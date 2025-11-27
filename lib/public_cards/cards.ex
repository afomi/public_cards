defmodule PublicCards.Cards do
  @moduledoc """
  The Cards context.
  """

  import Ecto.Query, warn: false
  alias PublicCards.Repo

  alias PublicCards.Cards.Card

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
end
