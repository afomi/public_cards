defmodule PublicCards.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :namespace, :string, null: false
      add :slug, :string, null: false
      add :card_type, :string
      add :title, :string
      add :content, :map, default: %{}
      add :content_hash, :string
      add :version, :integer, default: 1
      add :terms, :string
      add :owner_email, :string
      add :status, :string, default: "draft"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cards, [:namespace, :slug])
    create index(:cards, [:owner_email])
    create index(:cards, [:status])
  end
end
