defmodule PublicCards.CardEventsTest do
  use PublicCards.DataCase

  alias PublicCards.Cards
  alias PublicCards.Cards.CardEvent

  describe "event-sourced cards" do
    test "create_card_with_events/2 creates card and initial event" do
      attrs = %{
        namespace: "test",
        slug: "person",
        schema_type: "schema:Person"
      }

      assert {:ok, card} = Cards.create_card_with_events(attrs, author: "test@example.com")

      assert card.namespace == "test"
      assert card.slug == "person"
      assert card.schema_type == "schema:Person"
      assert card.head_event_id != nil

      # Check the create event was recorded
      events = Cards.get_events(card)
      assert length(events) == 1

      [event] = events
      assert event.op == "create"
      assert event.field == "schema:Person"
      assert event.author == "test@example.com"
      assert event.hash != nil
    end

    test "apply_event/3 adds set event and updates content" do
      {:ok, card} =
        Cards.create_card_with_events(
          %{namespace: "test", slug: "set-test", schema_type: "schema:Person"},
          author: "test@example.com"
        )

      {:ok, updated_card} =
        Cards.apply_event(
          card,
          %{op: "set", field: "schema:name", value: %{"@value" => "Test Person"}},
          author: "test@example.com"
        )

      assert updated_card.version == 2
      assert updated_card.content["schema:name"] == %{"@value" => "Test Person"}
      assert updated_card.content["@type"] == "schema:Person"

      events = Cards.get_events(updated_card)
      assert length(events) == 2

      [_create, set_event] = events
      assert set_event.op == "set"
      assert set_event.field == "schema:name"
      assert set_event.prev_event_id == card.head_event_id
    end

    test "apply_event/3 with unset removes field" do
      {:ok, card} =
        Cards.create_card_with_events(
          %{namespace: "test", slug: "unset-test", schema_type: "schema:Person"},
          author: "test@example.com"
        )

      {:ok, card} =
        Cards.apply_event(
          card,
          %{op: "set", field: "schema:name", value: %{"@value" => "Test"}},
          author: "test@example.com"
        )

      assert card.content["schema:name"] != nil

      {:ok, card} =
        Cards.apply_event(
          card,
          %{op: "unset", field: "schema:name"},
          author: "test@example.com"
        )

      refute Map.has_key?(card.content, "schema:name")
      assert card.content["@type"] == "schema:Person"
    end

    test "events form a merkle chain" do
      {:ok, card} =
        Cards.create_card_with_events(
          %{namespace: "test", slug: "chain-test", schema_type: "schema:Person"},
          author: "test@example.com"
        )

      {:ok, card} =
        Cards.apply_event(card, %{op: "set", field: "schema:name", value: %{"@value" => "A"}}, author: "a")

      {:ok, card} =
        Cards.apply_event(card, %{op: "set", field: "schema:email", value: %{"@value" => "B"}}, author: "b")

      events = Cards.get_events(card)
      assert length(events) == 3

      [e1, e2, e3] = events

      # First event has no prev
      assert e1.prev_event_id == nil
      # Second event points to first
      assert e2.prev_event_id == e1.id
      # Third event points to second
      assert e3.prev_event_id == e2.id

      # Each event has a unique hash
      hashes = Enum.map(events, & &1.hash)
      assert length(Enum.uniq(hashes)) == 3
    end

    test "rebuild_content/1 recomputes state from events" do
      {:ok, card} =
        Cards.create_card_with_events(
          %{namespace: "test", slug: "rebuild-test", schema_type: "schema:Person"},
          author: "test@example.com"
        )

      {:ok, card} =
        Cards.apply_event(card, %{op: "set", field: "schema:name", value: %{"@value" => "Name"}}, [])

      {:ok, card} =
        Cards.apply_event(card, %{op: "set", field: "schema:email", value: %{"@value" => "email@test.com"}}, [])

      {:ok, _card} =
        Cards.apply_event(card, %{op: "unset", field: "schema:email"}, [])

      content = Cards.rebuild_content(card.id)

      assert content["@type"] == "schema:Person"
      assert content["schema:name"] == %{"@value" => "Name"}
      refute Map.has_key?(content, "schema:email")
    end

    test "get_events_for_sync/1 returns events in order" do
      {:ok, card1} =
        Cards.create_card_with_events(
          %{namespace: "sync", slug: "card1", schema_type: "schema:Person"},
          []
        )

      {:ok, _card2} =
        Cards.create_card_with_events(
          %{namespace: "sync", slug: "card2", schema_type: "schema:Organization"},
          []
        )

      {:ok, _card1} =
        Cards.apply_event(card1, %{op: "set", field: "schema:name", value: %{"@value" => "Test"}}, [])

      # Get all events
      all_events = Cards.get_events_for_sync()
      assert length(all_events) == 3

      # Get only Person events
      person_events = Cards.get_events_for_sync(types: ["schema:Person"])
      assert length(person_events) == 2
    end
  end

  describe "CardEvent changeset" do
    test "computes hash automatically" do
      changeset =
        CardEvent.changeset(%CardEvent{}, %{
          card_id: Ecto.UUID.generate(),
          op: "create",
          field: "schema:Person"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :hash) != nil
    end

    test "validates operation" do
      changeset =
        CardEvent.changeset(%CardEvent{}, %{
          card_id: Ecto.UUID.generate(),
          op: "invalid_op",
          field: "test"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).op
    end

    test "create requires field" do
      changeset =
        CardEvent.changeset(%CardEvent{}, %{
          card_id: Ecto.UUID.generate(),
          op: "create"
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).field
    end
  end
end
