defmodule PublicCardsWeb.PageController do
  use PublicCardsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
