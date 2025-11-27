defmodule PublicCardsWeb.CardLive.Show do
  use PublicCardsWeb, :live_view

  alias PublicCards.Cards

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Card {@card.id}
        <:subtitle>This is a card record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/cards"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/cards/#{@card}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit card
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Namespace">{@card.namespace}</:item>
        <:item title="Slug">{@card.slug}</:item>
        <:item title="Title">{@card.title}</:item>
        <:item title="Type">{@card.card_type}</:item>
        <:item title="Version">v{@card.version}</:item>
        <:item title="Terms">{@card.terms}</:item>
        <:item title="Owner">{@card.owner_email}</:item>
        <:item title="Status">{@card.status}</:item>
        <:item title="Content Hash">
          <code class="text-xs">{@card.content_hash}</code>
        </:item>
      </.list>

      <div class="mt-8">
        <h3 class="text-sm font-medium text-slate-500 mb-3">Content</h3>
        <pre class="bg-slate-50 border border-slate-200 p-4 rounded overflow-auto text-sm text-slate-700"><code>{Jason.encode!(@card.content, pretty: true)}</code></pre>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Card")
     |> assign(:card, Cards.get_card!(id))}
  end
end
