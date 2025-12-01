defmodule PublicCards.Repo.Migrations.CreateCardEvents do
  use Ecto.Migration

  def change do
    create table(:card_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :card_id, references(:cards, type: :binary_id, on_delete: :delete_all), null: false
      add :prev_event_id, references(:card_events, type: :binary_id, on_delete: :nothing)

      # Event operation: create, set, unset
      add :op, :string, null: false

      # For :create op, this is the @type (e.g., "schema:Person")
      # For :set/:unset ops, this is the field name (e.g., "schema:name")
      add :field, :string

      # The value being set (JSON-encoded for complex values)
      add :value, :map

      # Content-addressable hash of this event (SHA256)
      add :hash, :string, null: false

      # Author identity (email for now, DID later)
      add :author, :string

      # Signature of the event (for verification)
      add :signature, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    # Index for fetching events by card
    create index(:card_events, [:card_id])

    # Index for Merkle chain traversal
    create index(:card_events, [:prev_event_id])

    # Unique constraint on hash (content-addressable)
    create unique_index(:card_events, [:hash])

    # Index for sync queries (events since timestamp)
    create index(:card_events, [:inserted_at])
  end
end
