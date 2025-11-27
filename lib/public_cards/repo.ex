defmodule PublicCards.Repo do
  use Ecto.Repo,
    otp_app: :public_cards,
    adapter: Ecto.Adapters.Postgres
end
