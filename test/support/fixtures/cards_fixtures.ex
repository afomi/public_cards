defmodule PublicCards.CardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PublicCards.Cards` context.
  """

  @doc """
  Generate a card.
  """
  def card_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    {:ok, card} =
      attrs
      |> Enum.into(%{
        card_type: "profile",
        content: %{"front" => %{"name" => "Test"}, "back" => %{}},
        namespace: "test-ns-#{unique_id}",
        owner_email: "test@example.com",
        slug: "test-card-#{unique_id}",
        status: "draft",
        terms: "cc-by",
        title: "Test Card"
      })
      |> PublicCards.Cards.create_card()

    card
  end
end
