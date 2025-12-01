defmodule PublicCards.Cards do
  @moduledoc """
  The Cards context.

  Cards are event-sourced. Each modification is recorded as an immutable event
  in a Merkle chain. The card's `content` field is a materialized view computed
  from folding all events.

  ## Event Operations

  - `:create` - Initialize a card with a Schema.org type
  - `:set` - Set or update a field value
  - `:unset` - Remove a field

  ## Example

      # Create a card with event sourcing
      {:ok, card} = Cards.create_card_with_events(%{
        namespace: "ryan",
        slug: "profile",
        schema_type: "schema:Person"
      }, author: "ryan@example.com")

      # Add a field
      {:ok, card} = Cards.apply_event(card, %{
        op: "set",
        field: "schema:name",
        value: %{"@value" => "Ryan"}
      }, author: "ryan@example.com")
  """

  import Ecto.Query, warn: false
  alias PublicCards.Repo

  alias PublicCards.Cards.Card
  alias PublicCards.Cards.CardEvent

  @doc """
  Returns the list of cards.

  ## Examples

      iex> list_cards()
      [%Card{}, ...]

  """
  def list_cards do
    Repo.all(Card)
  end

  @doc """
  Gets a single card.

  Raises `Ecto.NoResultsError` if the Card does not exist.

  ## Examples

      iex> get_card!(123)
      %Card{}

      iex> get_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_card!(id), do: Repo.get!(Card, id)

  @doc """
  Gets a single card, returns nil if not found.
  """
  def get_card(id), do: Repo.get(Card, id)

  @doc """
  Creates a card.

  ## Examples

      iex> create_card(%{field: value})
      {:ok, %Card{}}

      iex> create_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_card(attrs) do
    %Card{}
    |> Card.changeset(attrs)
    |> maybe_compute_content_hash()
    |> Repo.insert()
  end

  @doc """
  Updates a card.

  ## Examples

      iex> update_card(card, %{field: new_value})
      {:ok, %Card{}}

      iex> update_card(card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> maybe_compute_content_hash()
    |> maybe_bump_version(card)
    |> Repo.update()
  end

  @doc """
  Deletes a card.

  ## Examples

      iex> delete_card(card)
      {:ok, %Card{}}

      iex> delete_card(card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking card changes.

  ## Examples

      iex> change_card(card)
      %Ecto.Changeset{data: %Card{}}

  """
  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  @doc """
  Computes SHA256 hash of content for version detection.
  """
  def compute_content_hash(content) when is_map(content) do
    content
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  def compute_content_hash(_), do: nil

  # Private helpers

  defp maybe_compute_content_hash(changeset) do
    case Ecto.Changeset.get_change(changeset, :content) do
      nil -> changeset
      content -> Ecto.Changeset.put_change(changeset, :content_hash, compute_content_hash(content))
    end
  end

  defp maybe_bump_version(changeset, card) do
    if Ecto.Changeset.get_change(changeset, :content) do
      Ecto.Changeset.put_change(changeset, :version, (card.version || 0) + 1)
    else
      changeset
    end
  end

  # ===========================================================================
  # Event Sourcing
  # ===========================================================================

  @doc """
  Creates a new card with an initial :create event.

  ## Options

  - `:author` - The author identity (email or DID)

  ## Example

      {:ok, card} = Cards.create_card_with_events(%{
        namespace: "ryan",
        slug: "profile",
        schema_type: "schema:Person"
      }, author: "ryan@example.com")
  """
  def create_card_with_events(attrs, opts \\ []) do
    author = Keyword.get(opts, :author)
    schema_type = Map.get(attrs, :schema_type) || Map.get(attrs, "schema_type")

    Repo.transaction(fn ->
      # Create the card first
      case create_card(attrs) do
        {:ok, card} ->
          # Create the initial :create event
          event_attrs = %{
            card_id: card.id,
            op: "create",
            field: schema_type,
            author: author
          }

          case %CardEvent{} |> CardEvent.changeset(event_attrs) |> Repo.insert() do
            {:ok, event} ->
              # Update card with head_event_id
              {:ok, card} =
                card
                |> Card.changeset(%{head_event_id: event.id})
                |> Repo.update()

              card

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Applies an event to a card, updating its materialized state.

  ## Parameters

  - `card` - The card to update
  - `event_attrs` - Map with `:op`, `:field`, and optionally `:value`
  - `opts` - Options including `:author`

  ## Example

      {:ok, card} = Cards.apply_event(card, %{
        op: "set",
        field: "schema:name",
        value: %{"@value" => "Ryan"}
      }, author: "ryan@example.com")
  """
  def apply_event(%Card{} = card, event_attrs, opts \\ []) do
    author = Keyword.get(opts, :author)

    Repo.transaction(fn ->
      # Build event with chain reference
      full_event_attrs =
        event_attrs
        |> Map.put(:card_id, card.id)
        |> Map.put(:prev_event_id, card.head_event_id)
        |> Map.put(:author, author)

      case %CardEvent{} |> CardEvent.changeset(full_event_attrs) |> Repo.insert() do
        {:ok, event} ->
          # Rebuild content from events
          new_content = rebuild_content(card.id)
          new_hash = compute_content_hash(new_content)
          new_version = (card.version || 0) + 1

          # Update card with new state
          {:ok, updated_card} =
            card
            |> Card.changeset(%{
              content: new_content,
              content_hash: new_hash,
              version: new_version,
              head_event_id: event.id
            })
            |> Repo.update()

          updated_card

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Gets all events for a card, ordered by insertion time.
  """
  def get_events(%Card{id: card_id}), do: get_events(card_id)

  def get_events(card_id) when is_binary(card_id) do
    CardEvent
    |> where([e], e.card_id == ^card_id)
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets events for sync, optionally filtered by timestamp and types.

  ## Options

  - `:since` - Only events after this hash
  - `:types` - List of schema types to include
  - `:limit` - Maximum number of events to return
  """
  def get_events_for_sync(opts \\ []) do
    since_hash = Keyword.get(opts, :since)
    types = Keyword.get(opts, :types)
    limit = Keyword.get(opts, :limit, 100)

    query = from(e in CardEvent, order_by: [asc: e.inserted_at], limit: ^limit)

    query =
      if since_hash do
        # Find the timestamp of the 'since' event
        case Repo.get_by(CardEvent, hash: since_hash) do
          nil ->
            query

          since_event ->
            from(e in query, where: e.inserted_at > ^since_event.inserted_at)
        end
      else
        query
      end

    query =
      if types && types != [] do
        # Filter by schema type (join to cards)
        from(e in query,
          join: c in Card,
          on: c.id == e.card_id,
          where: c.schema_type in ^types
        )
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Rebuilds a card's content by folding all its events.

  This is used to compute the materialized view from the event log.
  """
  def rebuild_content(card_id) do
    events = get_events(card_id)
    fold_events(events)
  end

  @doc """
  Rebuilds a card's state from its events.

  Useful for verifying integrity or recovering from corruption.
  """
  def rebuild_card(%Card{} = card) do
    content = rebuild_content(card.id)
    hash = compute_content_hash(content)

    # Get schema_type from create event
    schema_type =
      case get_events(card.id) do
        [%{op: "create", field: type} | _] -> type
        _ -> nil
      end

    card
    |> Card.changeset(%{
      content: content,
      content_hash: hash,
      schema_type: schema_type
    })
    |> Repo.update()
  end

  # Fold events into a content map
  defp fold_events(events) do
    Enum.reduce(events, %{}, fn event, acc ->
      case event.op do
        "create" ->
          # Initialize with @type
          Map.put(acc, "@type", event.field)

        "set" ->
          # Set or update a field
          Map.put(acc, event.field, event.value)

        "unset" ->
          # Remove a field
          Map.delete(acc, event.field)

        _ ->
          acc
      end
    end)
  end
end
