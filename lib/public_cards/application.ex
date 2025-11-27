defmodule PublicCards.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PublicCardsWeb.Telemetry,
      PublicCards.Repo,
      {DNSCluster, query: Application.get_env(:public_cards, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PublicCards.PubSub},
      # Start a worker by calling: PublicCards.Worker.start_link(arg)
      # {PublicCards.Worker, arg},
      # Start to serve requests, typically the last entry
      PublicCardsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PublicCards.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PublicCardsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
