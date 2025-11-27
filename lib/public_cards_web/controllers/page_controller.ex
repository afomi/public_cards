defmodule PublicCardsWeb.PageController do
  use PublicCardsWeb, :controller

  alias PublicCards.Cards

  def home(conn, _params) do
    cards = Cards.list_cards() |> Enum.take(3)
    render(conn, :home, cards: cards)
  end
end
