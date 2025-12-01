defmodule PublicCardsWeb.Api.SchemaController do
  @moduledoc """
  API endpoint for exploring Schema.org types and properties.

  This helps clients understand what types of cards can be created
  and what properties are valid for each type.
  """
  use PublicCardsWeb, :controller

  alias PublicCards.Schema

  @doc """
  Lists Schema.org types.

  GET /api/schema/types
  GET /api/schema/types?highlighted=true  (returns curated subset)
  GET /api/schema/types?search=Person     (search by label)
  """
  def types(conn, params) do
    highlighted_types = Schema.highlighted_types()

    types =
      cond do
        params["highlighted"] == "true" ->
          Schema.list_highlighted_types()

        search = params["search"] ->
          Schema.search_types(search)

        true ->
          Schema.list_types()
      end

    type_details =
      Enum.map(types, fn type_id ->
        case Schema.get_type(type_id) do
          {:ok, type} ->
            %{
              id: type.id,
              label: type.label,
              comment: type.comment,
              highlighted: type_id in highlighted_types
            }

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{
      types: type_details,
      count: length(type_details),
      highlighted_count: length(highlighted_types)
    })
  end

  @doc """
  Gets details for a specific type, including its properties.

  GET /api/schema/types/:id
  """
  def show_type(conn, %{"id" => type_id}) do
    # Handle URL-encoded colons
    type_id = String.replace(type_id, "%3A", ":")

    # Ensure it has the schema: prefix
    type_id =
      if String.starts_with?(type_id, "schema:") do
        type_id
      else
        "schema:#{type_id}"
      end

    case Schema.get_type(type_id) do
      {:ok, type} ->
        {:ok, property_ids} = Schema.get_properties_for_type(type_id)

        properties =
          Enum.map(property_ids, fn prop_id ->
            case Schema.get_property(prop_id) do
              {:ok, prop} ->
                %{
                  id: prop.id,
                  label: prop.label,
                  comment: prop.comment,
                  range: prop.range_includes
                }

              _ ->
                %{id: prop_id}
            end
          end)
          |> Enum.sort_by(& &1.label)

        conn
        |> put_resp_content_type("application/json")
        |> json(%{
          type: %{
            id: type.id,
            label: type.label,
            comment: type.comment,
            subclass_of: type.subclass_of
          },
          properties: properties,
          property_count: length(properties)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Type not found", type_id: type_id})
    end
  end
end
