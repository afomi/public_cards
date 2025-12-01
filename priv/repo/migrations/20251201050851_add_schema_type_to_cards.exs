defmodule PublicCards.Repo.Migrations.AddSchemaTypeToCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      # Schema.org type (e.g., "schema:Person")
      add :schema_type, :string

      # Reference to the latest event in the chain
      add :head_event_id, references(:card_events, type: :binary_id, on_delete: :nothing)
    end

    create index(:cards, [:schema_type])
  end
end
