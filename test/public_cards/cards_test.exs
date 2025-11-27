defmodule PublicCards.CardsTest do
  use PublicCards.DataCase

  alias PublicCards.Cards

  describe "cards" do
    alias PublicCards.Cards.Card

    import PublicCards.CardsFixtures

    @invalid_attrs %{namespace: nil, slug: nil}

    test "list_cards/0 returns all cards" do
      card = card_fixture()
      assert Cards.list_cards() == [card]
    end

    test "get_card!/1 returns the card with given id" do
      card = card_fixture()
      assert Cards.get_card!(card.id) == card
    end

    test "create_card/1 with valid data creates a card" do
      valid_attrs = %{
        namespace: "test-namespace",
        slug: "test-slug",
        card_type: "profile",
        title: "Test Card",
        content: %{"front" => %{"name" => "Test"}},
        terms: "cc-by",
        owner_email: "test@example.com",
        status: "published"
      }

      assert {:ok, %Card{} = card} = Cards.create_card(valid_attrs)
      assert card.namespace == "test-namespace"
      assert card.slug == "test-slug"
      assert card.title == "Test Card"
      assert card.version == 1
      # content_hash should be computed automatically
      assert card.content_hash != nil
    end

    test "create_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Cards.create_card(@invalid_attrs)
    end

    test "create_card/1 validates namespace and slug format" do
      invalid_format = %{namespace: "Has Spaces", slug: "also spaces"}
      assert {:error, changeset} = Cards.create_card(invalid_format)
      assert "must be lowercase alphanumeric with hyphens" in errors_on(changeset).namespace
    end

    test "update_card/2 with valid data updates the card" do
      card = card_fixture()
      update_attrs = %{title: "Updated Title", status: "published"}

      assert {:ok, %Card{} = updated} = Cards.update_card(card, update_attrs)
      assert updated.title == "Updated Title"
      assert updated.status == "published"
    end

    test "update_card/2 bumps version when content changes" do
      card = card_fixture()
      original_version = card.version
      original_hash = card.content_hash

      update_attrs = %{content: %{"front" => %{"name" => "Changed"}}}
      assert {:ok, %Card{} = updated} = Cards.update_card(card, update_attrs)

      assert updated.version == original_version + 1
      assert updated.content_hash != original_hash
    end

    test "delete_card/1 deletes the card" do
      card = card_fixture()
      assert {:ok, %Card{}} = Cards.delete_card(card)
      assert_raise Ecto.NoResultsError, fn -> Cards.get_card!(card.id) end
    end

    test "change_card/1 returns a card changeset" do
      card = card_fixture()
      assert %Ecto.Changeset{} = Cards.change_card(card)
    end
  end

  describe "compute_content_hash/1" do
    test "returns consistent hash for same content" do
      content = %{"front" => %{"name" => "Test"}}
      hash1 = Cards.compute_content_hash(content)
      hash2 = Cards.compute_content_hash(content)
      assert hash1 == hash2
    end

    test "returns different hash for different content" do
      hash1 = Cards.compute_content_hash(%{"a" => 1})
      hash2 = Cards.compute_content_hash(%{"a" => 2})
      assert hash1 != hash2
    end

    test "returns nil for non-map content" do
      assert Cards.compute_content_hash(nil) == nil
      assert Cards.compute_content_hash("string") == nil
    end
  end
end
