defmodule PublicCardsWeb.SchemaLive.Index do
  use PublicCardsWeb, :live_view

  alias PublicCards.Schema

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Schema.org Types
        <:subtitle>
          Browse {@total_count} types from the Schema.org vocabulary
        </:subtitle>
      </.header>

      <div class="mt-6 space-y-4">
        <form phx-change="search" phx-submit="search" class="flex gap-4 items-end">
          <div class="flex-1">
            <label
              for="search"
              class="block text-sm font-medium text-slate-700"
            >
              Search types
            </label>
            <input
              type="text"
              name="query"
              id="search"
              value={@query}
              placeholder="e.g. Person, Organization, Event..."
              phx-debounce="300"
              class="mt-1 block w-full rounded-md border-slate-300 shadow-sm focus:border-slate-500 focus:ring-slate-500 sm:text-sm"
            />
          </div>
          <div>
            <label class="flex items-center gap-2 text-sm text-slate-600">
              <input
                type="checkbox"
                name="highlighted_only"
                value="true"
                checked={@highlighted_only}
                class="rounded border-slate-300 text-slate-600 focus:ring-slate-500"
              />
              Featured only
            </label>
          </div>
        </form>

        <div class="text-sm text-slate-500">
          Showing {@filtered_count} types
          <%= if @highlighted_only do %>
            (featured subset)
          <% end %>
          <%= if @query != "" do %>
            matching "<span class="font-medium">{@query}</span>"
          <% end %>
        </div>
      </div>

      <div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div
          :for={type <- @types}
          class={[
            "relative rounded-lg border p-4 hover:border-slate-400 transition-colors",
            type.highlighted && "border-slate-400 bg-slate-50",
            !type.highlighted && "border-slate-200"
          ]}
        >
          <div class="flex items-start justify-between gap-2">
            <div class="min-w-0 flex-1">
              <h3 class="font-medium text-slate-900 truncate">
                <.link
                  navigate={~p"/schema/#{type.id}"}
                  class="hover:text-slate-600"
                >
                  {type.label || type.id}
                </.link>
              </h3>
              <p class="mt-1 text-xs text-slate-500 font-mono truncate">
                {type.id}
              </p>
            </div>
            <span
              :if={type.highlighted}
              class="inline-flex items-center rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600"
            >
              Featured
            </span>
          </div>
          <p
            :if={type.comment && type.comment != ""}
            class="mt-2 text-sm text-slate-600 line-clamp-2"
          >
            {type.comment}
          </p>
        </div>
      </div>

      <div
        :if={@filtered_count == 0}
        class="mt-8 text-center py-12 text-slate-500"
      >
        <.icon
          name="hero-magnifying-glass"
          class="mx-auto h-12 w-12 text-slate-400"
        />
        <p class="mt-2">No types found matching your search.</p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    types = load_types("", false)
    highlighted_types = Schema.highlighted_types()

    {:ok,
     socket
     |> assign(:page_title, "Schema.org Types")
     |> assign(:query, "")
     |> assign(:highlighted_only, false)
     |> assign(:types, types)
     |> assign(:filtered_count, length(types))
     |> assign(:total_count, length(Schema.list_types()))
     |> assign(:highlighted_types, highlighted_types)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params["q"] || ""
    highlighted_only = params["featured"] == "true"

    types = load_types(query, highlighted_only)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:highlighted_only, highlighted_only)
     |> assign(:types, types)
     |> assign(:filtered_count, length(types))}
  end

  @impl true
  def handle_event("search", %{"query" => query} = params, socket) do
    highlighted_only = params["highlighted_only"] == "true"

    query_params =
      []
      |> then(fn p -> if query != "", do: [{"q", query} | p], else: p end)
      |> then(fn p -> if highlighted_only, do: [{"featured", "true"} | p], else: p end)

    {:noreply, push_patch(socket, to: ~p"/schema?#{query_params}")}
  end

  defp load_types(query, highlighted_only) do
    highlighted_types = Schema.highlighted_types()

    type_ids =
      cond do
        highlighted_only && query != "" ->
          Schema.search_types(query)
          |> Enum.filter(&(&1 in highlighted_types))

        highlighted_only ->
          Schema.list_highlighted_types()

        query != "" ->
          Schema.search_types(query)

        true ->
          Schema.list_types()
      end

    type_ids
    |> Enum.map(fn type_id ->
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
    |> Enum.sort_by(fn type ->
      {!type.highlighted, type.label || type.id}
    end)
  end
end
