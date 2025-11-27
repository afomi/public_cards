defmodule PublicCardsWeb.PageControllerTest do
  use PublicCardsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Public Cards"
    assert html_response(conn, 200) =~ "Structured, public data objects you own"
  end
end
