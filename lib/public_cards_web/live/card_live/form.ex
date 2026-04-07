defmodule PublicCardsWeb.CardLive.Form do
  use PublicCardsWeb, :live_view

  alias PublicCards.Cards
  alias PublicCards.Cards.Card
  alias PublicCards.Schema

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>
          <%= if @schema_type do %>
            Creating a <span class="font-mono">{@schema_type.label || @schema_type.id}</span> card
          <% else %>
            Use this form to manage card records in your database.
          <% end %>
        </:subtitle>
        <:actions>
          <button
            :if={@schema_type && Mix.env() != :prod}
            type="button"
            phx-click="fill_sample_data"
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-600 bg-slate-100 rounded hover:bg-slate-200 transition"
          >
            <.icon name="hero-beaker" class="w-4 h-4" /> Fill Sample Data
          </button>
        </:actions>
      </.header>

      <.form
        for={@form}
        id="card-form"
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-2 gap-4">
          <.input
            field={@form[:namespace]}
            type="text"
            label="Namespace"
            placeholder="my-namespace"
          />
          <.input
            field={@form[:slug]}
            type="text"
            label="Slug"
            placeholder="my-card"
          />
        </div>
        <.input
          field={@form[:title]}
          type="text"
          label="Title"
        />
        <div class="grid grid-cols-2 gap-4">
          <.input
            field={@form[:card_type]}
            type="select"
            label="Card Type"
            options={["profile", "project", "jurisdiction", "trading"]}
          />
          <.input
            field={@form[:terms]}
            type="select"
            label="Terms"
            options={["cc-by", "cc0", "all-rights-reserved"]}
          />
        </div>
        <.input
          field={@form[:owner_email]}
          type="email"
          label="Owner Email"
        />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={["draft", "published"]}
        />

        <%= if @schema_type do %>
          <input
            type="hidden"
            name="card[schema_type]"
            value={@schema_type.id}
          />

          <div class="mt-8 border-t border-slate-200 pt-6">
            <h3 class="text-lg font-semibold text-slate-900 mb-4">
              {@schema_type.label || @schema_type.id} Properties
            </h3>
            <p class="text-sm text-slate-500 mb-6">
              {@schema_type.comment}
            </p>

            <div class="space-y-4">
              <div
                :for={prop <- @schema_properties}
                class="relative"
              >
                <.schema_field
                  property={prop}
                  value={Map.get(@schema_values, prop.id, "")}
                />
              </div>
            </div>
          </div>
        <% else %>
          <div class="mb-4">
            <label class="block text-sm font-medium text-slate-700 mb-1">
              Content (JSON)
            </label>
            <textarea
              name="card[content_json]"
              rows="10"
              class="w-full px-3 py-2 border border-slate-300 rounded text-sm font-mono bg-white focus:outline-none focus:ring-2 focus:ring-slate-500 focus:border-slate-500"
              placeholder='{"front": {}, "back": {}}'
            >{@content_json}</textarea>
          </div>
        <% end %>

        <footer class="mt-6 pt-6 border-t border-slate-200 flex gap-3">
          <.button
            phx-disable-with="Saving..."
            variant="primary"
          >
            Save Card
          </.button>
          <.button navigate={return_path(@return_to, @card)}>
            Cancel
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  attr :property, :map, required: true
  attr :value, :string, default: ""

  defp schema_field(assigns) do
    ~H"""
    <div>
      <label
        for={"schema_#{@property.id}"}
        class="block text-sm font-medium text-slate-700 mb-1"
      >
        {@property.label || @property.id}
      </label>
      <p
        :if={@property.comment && @property.comment != ""}
        class="text-xs text-slate-500 mb-1"
      >
        {@property.comment}
      </p>
      <%= if long_text_field?(@property) do %>
        <textarea
          id={"schema_#{@property.id}"}
          name={"card[schema_fields][#{@property.id}]"}
          rows="3"
          class="w-full px-3 py-2 border border-slate-300 rounded text-sm bg-white focus:outline-none focus:ring-2 focus:ring-slate-500 focus:border-slate-500"
        >{@value}</textarea>
      <% else %>
        <input
          type={input_type_for(@property)}
          id={"schema_#{@property.id}"}
          name={"card[schema_fields][#{@property.id}]"}
          value={@value}
          class="w-full px-3 py-2 border border-slate-300 rounded text-sm bg-white focus:outline-none focus:ring-2 focus:ring-slate-500 focus:border-slate-500"
        />
      <% end %>
      <p class="mt-1 text-xs text-slate-400 font-mono">
        {@property.id}
        <%= if @property.range && @property.range != [] do %>
          <span class="text-slate-300">|</span> expects: {Enum.join(@property.range, ", ")}
        <% end %>
      </p>
    </div>
    """
  end

  defp input_type_for(property) do
    range = property.range || []

    cond do
      "schema:URL" in range -> "url"
      "schema:Email" in range -> "email"
      "schema:Date" in range -> "date"
      "schema:DateTime" in range -> "datetime-local"
      "schema:Time" in range -> "time"
      "schema:Number" in range or "schema:Integer" in range -> "number"
      "schema:Boolean" in range -> "checkbox"
      true -> "text"
    end
  end

  defp long_text_field?(property) do
    range = property.range || []
    label = String.downcase(property.label || "")

    "schema:Text" in range or
      String.contains?(label, "description") or
      String.contains?(label, "comment") or
      String.contains?(label, "content") or
      String.contains?(label, "body") or
      String.contains?(label, "text")
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id} = params) do
    card = Cards.get_card!(id)
    content_json = Jason.encode!(card.content || %{}, pretty: true)

    {schema_type, schema_properties, schema_values} =
      load_schema_for_card(card, params)

    socket
    |> assign(:page_title, "Edit Card")
    |> assign(:card, card)
    |> assign(:content_json, content_json)
    |> assign(:schema_type, schema_type)
    |> assign(:schema_properties, schema_properties)
    |> assign(:schema_values, schema_values)
    |> assign(:form, to_form(Cards.change_card(card)))
  end

  defp apply_action(socket, :new, params) do
    card = %Card{}
    default_content = %{"front" => %{}, "back" => %{}}

    {schema_type, schema_properties, schema_values} =
      load_schema_from_params(params)

    socket
    |> assign(:page_title, "New Card")
    |> assign(:card, card)
    |> assign(:content_json, Jason.encode!(default_content, pretty: true))
    |> assign(:schema_type, schema_type)
    |> assign(:schema_properties, schema_properties)
    |> assign(:schema_values, schema_values)
    |> assign(:form, to_form(Cards.change_card(card)))
  end

  defp load_schema_from_params(params) do
    case params["type"] do
      nil ->
        {nil, [], %{}}

      type_id ->
        type_id = normalize_type_id(type_id)
        load_schema_type(type_id)
    end
  end

  defp load_schema_for_card(card, params) do
    type_id = params["type"] || card.schema_type

    if type_id do
      type_id = normalize_type_id(type_id)
      {schema_type, schema_properties, _} = load_schema_type(type_id)

      schema_values =
        (card.content || %{})
        |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "schema:") end)
        |> Enum.into(%{})

      {schema_type, schema_properties, schema_values}
    else
      {nil, [], %{}}
    end
  end

  defp load_schema_type(type_id) do
    case Schema.get_type(type_id) do
      {:ok, type} ->
        {:ok, property_ids} = Schema.get_properties_for_type(type_id)

        properties =
          property_ids
          |> Enum.map(fn prop_id ->
            case Schema.get_property(prop_id) do
              {:ok, prop} ->
                %{
                  id: prop.id,
                  label: prop.label,
                  comment: prop.comment,
                  range: prop.range_includes
                }

              _ ->
                %{id: prop_id, label: nil, comment: nil, range: []}
            end
          end)
          |> Enum.sort_by(fn prop -> prop.label || prop.id end)

        {type, properties, %{}}

      {:error, _} ->
        {nil, [], %{}}
    end
  end

  defp normalize_type_id(type_id) do
    type_id = URI.decode(type_id)

    if String.starts_with?(type_id, "schema:") do
      type_id
    else
      "schema:#{type_id}"
    end
  end

  @impl true
  def handle_event("validate", %{"card" => card_params}, socket) do
    {card_params, content_json, schema_values} =
      process_card_params(card_params, socket.assigns.schema_type)

    changeset = Cards.change_card(socket.assigns.card, card_params)

    {:noreply,
     socket
     |> assign(:content_json, content_json)
     |> assign(:schema_values, schema_values)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"card" => card_params}, socket) do
    {card_params, _content_json, _schema_values} =
      process_card_params(card_params, socket.assigns.schema_type)

    save_card(socket, socket.assigns.live_action, card_params)
  end

  def handle_event("fill_sample_data", _params, socket) do
    schema_type = socket.assigns.schema_type
    properties = socket.assigns.schema_properties

    sample_values = generate_sample_data(schema_type, properties)

    type_label =
      (schema_type.label || schema_type.id)
      |> String.replace("schema:", "")
      |> String.downcase()

    sample_card_attrs = %{
      "namespace" => "examples",
      "slug" => "sample-#{type_label}-#{:rand.uniform(999)}",
      "title" => "Sample #{schema_type.label || schema_type.id}",
      "card_type" => "profile",
      "terms" => "cc-by",
      "owner_email" => "sample@example.com",
      "status" => "draft"
    }

    changeset = Cards.change_card(socket.assigns.card, sample_card_attrs)

    {:noreply,
     socket
     |> assign(:schema_values, sample_values)
     |> assign(:form, to_form(changeset))}
  end

  defp process_card_params(card_params, schema_type) do
    if schema_type do
      process_schema_params(card_params, schema_type)
    else
      process_json_params(card_params)
    end
  end

  defp process_schema_params(card_params, schema_type) do
    schema_fields = Map.get(card_params, "schema_fields", %{})

    content =
      schema_fields
      |> Enum.reject(fn {_k, v} -> v == "" end)
      |> Enum.into(%{})
      |> Map.put("@type", schema_type.id)

    card_params =
      card_params
      |> Map.delete("schema_fields")
      |> Map.put("content", content)
      |> Map.put("schema_type", schema_type.id)

    content_json = Jason.encode!(content, pretty: true)
    {card_params, content_json, schema_fields}
  end

  defp process_json_params(card_params) do
    content_json = Map.get(card_params, "content_json", "{}")

    content =
      case Jason.decode(content_json) do
        {:ok, parsed} -> parsed
        {:error, _} -> %{}
      end

    card_params =
      card_params
      |> Map.delete("content_json")
      |> Map.put("content", content)

    {card_params, content_json, %{}}
  end

  defp save_card(socket, :edit, card_params) do
    case Cards.update_card(socket.assigns.card, card_params) do
      {:ok, card} ->
        {:noreply,
         socket
         |> put_flash(:info, "Card updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, card))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_card(socket, :new, card_params) do
    case Cards.create_card(card_params) do
      {:ok, card} ->
        {:noreply,
         socket
         |> put_flash(:info, "Card created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, card))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _card), do: ~p"/cards"
  defp return_path("show", card), do: ~p"/cards/#{card}"

  defp generate_sample_data(_schema_type, properties) do
    properties
    |> Enum.take(15)
    |> Enum.map(fn prop ->
      {prop.id, generate_sample_value(prop)}
    end)
    |> Enum.reject(fn {_k, v} -> v == "" end)
    |> Enum.into(%{})
  end

  defp generate_sample_value(property) do
    range = property.range || []
    label = String.downcase(property.label || "")
    id = String.downcase(property.id || "")

    cond do
      String.contains?(id, "email") or String.contains?(label, "email") ->
        "sample@example.com"

      String.contains?(id, "telephone") or String.contains?(label, "phone") ->
        "+1-555-123-4567"

      String.contains?(id, "url") or "schema:URL" in range ->
        "https://example.com"

      String.contains?(id, "name") and String.contains?(id, "given") ->
        "Jane"

      String.contains?(id, "name") and String.contains?(id, "family") ->
        "Doe"

      String.contains?(id, "name") and String.contains?(id, "additional") ->
        "Marie"

      String.contains?(id, "name") ->
        "Jane Doe"

      String.contains?(id, "title") or String.contains?(label, "title") ->
        "Software Engineer"

      String.contains?(id, "description") or String.contains?(label, "description") ->
        "A sample description for testing purposes."

      String.contains?(id, "street") ->
        "123 Main Street"

      String.contains?(id, "locality") or String.contains?(label, "city") ->
        "San Francisco"

      String.contains?(id, "region") or String.contains?(label, "state") ->
        "CA"

      String.contains?(id, "postalcode") or String.contains?(label, "zip") ->
        "94102"

      String.contains?(id, "country") ->
        "United States"

      String.contains?(id, "addresscountry") ->
        "US"

      String.contains?(id, "image") ->
        "https://picsum.photos/200"

      String.contains?(id, "logo") ->
        "https://picsum.photos/100"

      "schema:Date" in range ->
        Date.utc_today() |> Date.to_iso8601()

      "schema:DateTime" in range ->
        DateTime.utc_now() |> DateTime.to_iso8601()

      "schema:Number" in range or "schema:Integer" in range ->
        "42"

      "schema:Boolean" in range ->
        "true"

      "schema:Text" in range ->
        "Sample text content for #{property.label || property.id}."

      true ->
        ""
    end
  end
end
