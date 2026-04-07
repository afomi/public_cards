defmodule PublicCards.Schema do
  @moduledoc """
  Schema.org vocabulary loader and validator.

  Parses the Schema.org JSON-LD definitions to provide:
  - Type information (classes)
  - Property definitions for each type
  - Validation of card fields against schema

  ## Usage

      # Get a type definition
      {:ok, person} = Schema.get_type("schema:Person")
      person.label  # "Person"
      person.properties  # ["schema:name", "schema:email", ...]

      # Validate a field for a type
      Schema.valid_property?("schema:Person", "schema:name")  # true
      Schema.valid_property?("schema:Person", "schema:invalid")  # false

      # List all available types
      Schema.list_types()
  """

  use GenServer
  require Logger

  @schema_file "tmp/schemaorg-current-https.jsonld"

  # Types we highlight in the UI (focused subset for MVP)
  @highlighted_types ~w(
    schema:Person
    schema:Organization
    schema:GovernmentOrganization
    schema:Place
    schema:Role
    schema:ContactPoint
  )

  defmodule Type do
    @moduledoc "A Schema.org type definition"
    defstruct [
      :id,
      :label,
      :comment,
      :subclass_of,
      :properties
    ]
  end

  defmodule Property do
    @moduledoc "A Schema.org property definition"
    defstruct [
      :id,
      :label,
      :comment,
      :domain_includes,
      :range_includes
    ]
  end

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a type definition by ID.

  ## Example

      {:ok, type} = Schema.get_type("schema:Person")
  """
  def get_type(type_id) do
    GenServer.call(__MODULE__, {:get_type, type_id})
  end

  @doc """
  Gets a property definition by ID.
  """
  def get_property(property_id) do
    GenServer.call(__MODULE__, {:get_property, property_id})
  end

  @doc """
  Lists all available Schema.org types.
  """
  def list_types do
    GenServer.call(__MODULE__, :list_types)
  end

  @doc """
  Lists the highlighted/featured types (curated subset for MVP).
  """
  def list_highlighted_types do
    GenServer.call(__MODULE__, :list_highlighted_types)
  end

  @doc """
  Searches types by label (case-insensitive).
  """
  def search_types(query) when is_binary(query) do
    GenServer.call(__MODULE__, {:search_types, query})
  end

  @doc """
  Gets all properties valid for a given type (including inherited).
  """
  def get_properties_for_type(type_id) do
    GenServer.call(__MODULE__, {:get_properties_for_type, type_id})
  end

  @doc """
  Checks if a property is valid for a given type.
  """
  def valid_property?(type_id, property_id) do
    case get_properties_for_type(type_id) do
      {:ok, properties} -> property_id in properties
      _ -> false
    end
  end

  @doc """
  Returns the list of highlighted/featured type IDs (curated subset).
  """
  def highlighted_types, do: @highlighted_types

  # Server callbacks

  @impl true
  def init(_opts) do
    # Load schema lazily or on startup
    state = %{
      types: %{},
      properties: %{},
      loaded: false
    }

    # Load schema in background
    send(self(), :load_schema)

    {:ok, state}
  end

  @impl true
  def handle_info(:load_schema, state) do
    case load_schema_file() do
      {:ok, {types, properties}} ->
        Logger.info(
          "Schema.org loaded: #{map_size(types)} types, #{map_size(properties)} properties"
        )

        {:noreply, %{state | types: types, properties: properties, loaded: true}}

      {:error, reason} ->
        Logger.warning("Failed to load Schema.org: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:get_type, type_id}, _from, state) do
    result =
      case Map.get(state.types, type_id) do
        nil -> {:error, :not_found}
        type -> {:ok, type}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_property, property_id}, _from, state) do
    result =
      case Map.get(state.properties, property_id) do
        nil -> {:error, :not_found}
        prop -> {:ok, prop}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:list_types, _from, state) do
    types =
      state.types
      |> Map.keys()
      |> Enum.sort()

    {:reply, types, state}
  end

  @impl true
  def handle_call(:list_highlighted_types, _from, state) do
    types =
      state.types
      |> Map.keys()
      |> Enum.filter(&(&1 in @highlighted_types))
      |> Enum.sort()

    {:reply, types, state}
  end

  @impl true
  def handle_call({:search_types, query}, _from, state) do
    query_lower = String.downcase(query)

    results =
      state.types
      |> Enum.filter(fn {_id, type} ->
        label = extract_label_string(type.label)
        String.contains?(String.downcase(label), query_lower)
      end)
      |> Enum.map(fn {id, _type} -> id end)
      |> Enum.sort()

    {:reply, results, state}
  end

  @impl true
  def handle_call({:get_properties_for_type, type_id}, _from, state) do
    result = collect_properties(type_id, state)
    {:reply, result, state}
  end

  # Private functions

  defp load_schema_file do
    path = Application.app_dir(:public_cards, @schema_file)

    # Fallback to relative path in dev
    path =
      if File.exists?(path) do
        path
      else
        Path.join(File.cwd!(), @schema_file)
      end

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> parse_schema(data)
          {:error, _} = err -> err
        end

      {:error, _} = err ->
        err
    end
  end

  defp parse_schema(%{"@graph" => graph}) do
    # Parse types (rdfs:Class)
    types =
      graph
      |> Enum.filter(&(&1["@type"] == "rdfs:Class"))
      |> Enum.map(&parse_type/1)
      |> Enum.into(%{})

    # Parse properties (rdf:Property)
    properties =
      graph
      |> Enum.filter(&(&1["@type"] == "rdf:Property"))
      |> Enum.map(&parse_property/1)
      |> Enum.into(%{})

    # Attach properties to types
    types = attach_properties_to_types(types, properties)

    {:ok, {types, properties}}
  end

  defp parse_schema(_), do: {:error, :invalid_format}

  defp parse_type(data) do
    id = data["@id"]

    type = %Type{
      id: id,
      label: extract_label_string(data["rdfs:label"]),
      comment: extract_label_string(data["rdfs:comment"]),
      subclass_of: extract_id(data["rdfs:subClassOf"]),
      properties: []
    }

    {id, type}
  end

  defp parse_property(data) do
    id = data["@id"]

    prop = %Property{
      id: id,
      label: extract_label_string(data["rdfs:label"]),
      comment: extract_label_string(data["rdfs:comment"]),
      domain_includes: extract_ids(data["schema:domainIncludes"]),
      range_includes: extract_ids(data["schema:rangeIncludes"])
    }

    {id, prop}
  end

  defp extract_id(nil), do: nil
  defp extract_id(%{"@id" => id}), do: id
  defp extract_id(list) when is_list(list), do: Enum.map(list, &extract_id/1) |> List.first()
  defp extract_id(_), do: nil

  defp extract_ids(nil), do: []
  defp extract_ids(%{"@id" => id}), do: [id]

  defp extract_ids(list) when is_list(list),
    do: Enum.map(list, &extract_id/1) |> Enum.reject(&is_nil/1)

  defp extract_ids(_), do: []

  # Extract string value from rdfs:label which can be a string or a map with @value/@language
  defp extract_label_string(nil), do: ""
  defp extract_label_string(label) when is_binary(label), do: label
  defp extract_label_string(%{"@value" => value}) when is_binary(value), do: value
  defp extract_label_string(_), do: ""

  defp attach_properties_to_types(types, properties) do
    # For each property, add it to its domain types
    Enum.reduce(properties, types, fn {prop_id, prop}, acc ->
      Enum.reduce(prop.domain_includes, acc, fn type_id, inner_acc ->
        case Map.get(inner_acc, type_id) do
          nil ->
            inner_acc

          type ->
            updated_type = %{type | properties: [prop_id | type.properties]}
            Map.put(inner_acc, type_id, updated_type)
        end
      end)
    end)
  end

  defp collect_properties(type_id, state) do
    case Map.get(state.types, type_id) do
      nil ->
        {:error, :type_not_found}

      type ->
        # Collect own properties + inherited from superclass
        own_props = type.properties || []

        inherited_props =
          if type.subclass_of do
            case collect_properties(type.subclass_of, state) do
              {:ok, props} -> props
              _ -> []
            end
          else
            []
          end

        {:ok, Enum.uniq(own_props ++ inherited_props)}
    end
  end
end
