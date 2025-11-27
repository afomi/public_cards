defmodule PublicCardsWeb.EmbedController do
  use PublicCardsWeb, :controller

  @embed_script File.read!("assets/js/embed.js")

  def script(conn, _params) do
    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, @embed_script)
  end
end
