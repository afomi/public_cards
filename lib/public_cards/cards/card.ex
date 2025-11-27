defmodule PublicCards.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

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
      :status
    ])
    |> validate_required([:namespace, :slug])
    |> unique_constraint([:namespace, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/, message: "must be lowercase alphanumeric with hyphens")
    |> validate_format(:namespace, ~r/^[a-z0-9\-]+$/, message: "must be lowercase alphanumeric with hyphens")
  end
end
