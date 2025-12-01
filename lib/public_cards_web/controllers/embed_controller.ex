defmodule PublicCardsWeb.EmbedController do
  use PublicCardsWeb, :controller

  def script(conn, _params) do
    embed_path = Application.app_dir(:public_cards, "priv/static/embed.js")

    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, File.read!(embed_path))
  end
end
