defmodule PublicCardsWeb.CardLive.Show do
  use PublicCardsWeb, :live_view

  alias PublicCards.Cards

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    card = Cards.get_card!(id)
    events = Cards.get_events(card)
    display_fields = extract_display_fields(card.content || %{}, card.schema_type || "")

    {:ok,
     socket
     |> assign(:page_title, "Show Card")
     |> assign(:card, card)
     |> assign(:events, events)
     |> assign(:display_fields, display_fields)}
  end

  attr :card, :map, required: true
  attr :display_fields, :map, required: true

  def card_preview(assigns) do
    ~H"""
    <div class="aspect-[3/4] bg-white border border-slate-200 rounded-lg shadow-sm overflow-hidden">
      <div class="h-full flex flex-col">
        <!-- Card front -->
        <div class="flex-1 p-6 flex flex-col justify-center">
          <%= if @card.schema_type do %>
            <.schema_card_content card={@card} display_fields={@display_fields} />
          <% else %>
            <.legacy_card_content card={@card} />
          <% end %>
        </div>
        <!-- Card footer -->
        <div class="px-4 py-3 bg-slate-50 border-t border-slate-100">
          <div class="flex items-center justify-between">
            <div class="text-xs text-slate-400 font-mono truncate">
              {@card.namespace}/{@card.slug}
            </div>
            <div class="text-xs text-slate-400">
              v{@card.version}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :card, :map, required: true
  attr :display_fields, :map, required: true

  defp schema_card_content(assigns) do
    ~H"""
    <div class="space-y-3">
      <!-- Type badge -->
      <div class="text-center">
        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-600">
          {format_type(@card.schema_type)}
        </span>
      </div>

      <!-- Primary field (name, title, etc) -->
      <div
        :if={@display_fields.primary}
        class="text-center"
      >
        <div class="text-xl font-semibold text-slate-900">
          {@display_fields.primary}
        </div>
      </div>

      <!-- Secondary field (job title, description, etc) -->
      <div
        :if={@display_fields.secondary}
        class="text-center"
      >
        <div class="text-sm text-slate-600">
          {@display_fields.secondary}
        </div>
      </div>

      <!-- Additional fields -->
      <div
        :if={@display_fields.details != []}
        class="pt-3 border-t border-slate-100 space-y-1"
      >
        <div
          :for={{label, value} <- Enum.take(@display_fields.details, 4)}
          class="flex text-xs"
        >
          <span class="text-slate-400 w-24 shrink-0">{label}</span>
          <span class="text-slate-600 truncate">{value}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :card, :map, required: true

  defp legacy_card_content(assigns) do
    ~H"""
    <div class="text-center">
      <%= if @card.content["front"]["name"] do %>
        <div class="text-lg font-semibold text-slate-900">
          {@card.content["front"]["name"]}
        </div>
      <% end %>
      <%= if @card.content["front"]["title"] do %>
        <div class="text-sm text-slate-600 mt-1">
          {@card.content["front"]["title"]}
        </div>
      <% end %>
      <%= if @card.content["front"]["tagline"] do %>
        <div class="text-xs text-slate-500 mt-2">
          {@card.content["front"]["tagline"]}
        </div>
      <% end %>
      <%= if !@card.content["front"] do %>
        <div class="text-slate-400 text-sm">
          {@card.title || "#{@card.namespace}/#{@card.slug}"}
        </div>
      <% end %>
    </div>
    """
  end

  defp extract_display_fields(content, schema_type) do
    primary =
      content["schema:name"] ||
        content["schema:givenName"] &&
          "#{content["schema:givenName"]} #{content["schema:familyName"]}" ||
        content["schema:legalName"] ||
        content["schema:streetAddress"]

    secondary =
      cond do
        String.contains?(schema_type, "Person") ->
          content["schema:jobTitle"] || content["schema:description"]

        String.contains?(schema_type, "Organization") ->
          content["schema:description"]

        String.contains?(schema_type, "PostalAddress") ->
          [
            content["schema:addressLocality"],
            content["schema:addressRegion"],
            content["schema:postalCode"]
          ]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        String.contains?(schema_type, "Place") ->
          content["schema:description"] || content["schema:address"]

        true ->
          content["schema:description"]
      end

    details =
      content
      |> Enum.filter(fn {k, v} ->
        String.starts_with?(k, "schema:") and
          k not in [
            "schema:name",
            "schema:givenName",
            "schema:familyName",
            "schema:jobTitle",
            "schema:description",
            "schema:legalName"
          ] and
          is_binary(v) and v != ""
      end)
      |> Enum.map(fn {k, v} ->
        label = k |> String.replace("schema:", "") |> Phoenix.Naming.humanize()
        {label, v}
      end)
      |> Enum.sort_by(fn {label, _} -> label end)

    %{primary: primary, secondary: secondary, details: details}
  end

  defp format_type(nil), do: "Card"

  defp format_type(type) do
    type
    |> String.replace("schema:", "")
    |> Phoenix.Naming.humanize()
  end
end
