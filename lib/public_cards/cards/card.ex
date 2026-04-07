defmodule PublicCards.Cards.Card do
  @moduledoc """
  A card is a structured, public data object.

  Cards are event-sourced: the `content` field is a materialized view
  computed from the card's event history. The `head_event_id` points
  to the latest event in the Merkle chain.

  ## Schema.org Types

  The `schema_type` field specifies the Schema.org type (e.g., "schema:Person").
  This determines which properties are valid for the card.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PublicCards.Cards.CardEvent

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cards" do
    field :namespace, :string
    field :slug, :string
    field :card_type, :string
    field :title, :string
    field :content, :map, default: %{}
    field :content_hash, :string
    field :version, :integer, default: 1
    field :terms, :string
    field :owner_email, :string
    field :status, :string, default: "draft"

    # Schema.org type (e.g., "schema:Person")
    field :schema_type, :string

    # Reference to the head of the event chain
    belongs_to :head_event, CardEvent, foreign_key: :head_event_id

    # All events for this card
    has_many :events, CardEvent

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [
      :namespace,
      :slug,
      :card_type,
      :title,
      :content,
      :content_hash,
      :version,
      :terms,
      :owner_email,
      :status,
      :schema_type,
      :head_event_id
    ])
    |> validate_required([:namespace, :slug])
    |> unique_constraint([:namespace, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> validate_format(:namespace, ~r/^[a-z0-9\-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> validate_length(:namespace, min: 1, max: 63)
    |> validate_length(:slug, min: 1, max: 63)
    |> validate_length(:title, max: 255)
  end
end
