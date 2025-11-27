defmodule PublicCardsWeb.Router do
  use PublicCardsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PublicCardsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PublicCardsWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Card routes
    live "/cards", CardLive.Index, :index
    live "/cards/new", CardLive.Form, :new
    live "/cards/:id", CardLive.Show, :show
    live "/cards/:id/edit", CardLive.Form, :edit

    # Pretty namespaced routes (future)
    # live "/c/:namespace/:slug", CardLive.Show, :show_by_slug

    # Embed script (served from assets)
    get "/embed.js", EmbedController, :script
  end

  # API routes for JSON access
  scope "/api", PublicCardsWeb.Api do
    pipe_through :api

    get "/cards/:id", CardController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:public_cards, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PublicCardsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
