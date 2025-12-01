defmodule PublicCards.Cards.CardEvent do
  @moduledoc """
  An immutable event in a card's history.

  Events form a Merkle chain - each event references the previous event's hash,
  creating a tamper-evident, content-addressable history.

  ## Operations

  - `:create` - Initialize a card with a Schema.org type
  - `:set` - Set or update a field value
  - `:unset` - Remove a field

  ## Hash Computation

  The event hash is computed from:
  - card_id
  - prev_event_id (or nil for first event)
  - op
  - field
  - value
  - author
  - timestamp

  This makes events content-addressable and verifiable.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @operations ~w(create set unset)

  schema "card_events" do
    field :op, :string
    field :field, :string
    field :value, :map
    field :hash, :string
    field :author, :string
    field :signature, :string

    belongs_to :card, PublicCards.Cards.Card
    belongs_to :prev_event, __MODULE__, foreign_key: :prev_event_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Creates a changeset for a new event.

  The hash is computed automatically from the event content.
  """
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:card_id, :prev_event_id, :op, :field, :value, :author, :signature])
    |> validate_required([:card_id, :op])
    |> validate_inclusion(:op, @operations)
    |> validate_operation_fields()
    |> compute_hash()
    |> unique_constraint(:hash)
  end

  # Validate that the right fields are present for each operation
  defp validate_operation_fields(changeset) do
    op = get_field(changeset, :op)

    case op do
      "create" ->
        # :create requires a field (the @type)
        validate_required(changeset, [:field])

      "set" ->
        # :set requires field and value
        changeset
        |> validate_required([:field])

      "unset" ->
        # :unset requires field
        validate_required(changeset, [:field])

      _ ->
        changeset
    end
  end

  # Compute the content-addressable hash
  defp compute_hash(changeset) do
    if changeset.valid? do
      hash_input = %{
        card_id: get_field(changeset, :card_id),
        prev_event_id: get_field(changeset, :prev_event_id),
        op: get_field(changeset, :op),
        field: get_field(changeset, :field),
        value: get_field(changeset, :value),
        author: get_field(changeset, :author),
        # Use current time if not set
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      hash =
        hash_input
        |> Jason.encode!()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)

      put_change(changeset, :hash, hash)
    else
      changeset
    end
  end

  @doc """
  Returns the list of valid operations.
  """
  def operations, do: @operations
end
