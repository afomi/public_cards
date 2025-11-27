defmodule PublicCardsWeb.CardLiveTest do
  use PublicCardsWeb.ConnCase

  import Phoenix.LiveViewTest
  import PublicCards.CardsFixtures

  @create_attrs %{
    namespace: "new-namespace",
    slug: "new-slug",
    title: "New Card",
    card_type: "profile",
    terms: "cc-by",
    status: "draft",
    owner_email: "new@example.com"
  }
  @update_attrs %{
    namespace: "updated-namespace",
    slug: "updated-slug",
    title: "Updated Card",
    card_type: "project",
    terms: "cc0",
    status: "published",
    owner_email: "updated@example.com"
  }
  @invalid_attrs %{namespace: "", slug: ""}
  defp create_card(_) do
    card = card_fixture()

    %{card: card}
  end

  describe "Index" do
    setup [:create_card]

    test "lists all cards", %{conn: conn, card: card} do
      {:ok, _index_live, html} = live(conn, ~p"/cards")

      assert html =~ "Listing Cards"
      assert html =~ card.namespace
    end

    test "saves new card", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/cards")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Card")
               |> render_click()
               |> follow_redirect(conn, ~p"/cards/new")

      assert render(form_live) =~ "New Card"

      assert form_live
             |> form("#card-form", card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#card-form", card: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cards")

      html = render(index_live)
      assert html =~ "Card created successfully"
      assert html =~ "new-namespace"
    end

    test "updates card in listing", %{conn: conn, card: card} do
      {:ok, index_live, _html} = live(conn, ~p"/cards")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#cards-#{card.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cards/#{card}/edit")

      assert render(form_live) =~ "Edit Card"

      assert form_live
             |> form("#card-form", card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#card-form", card: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cards")

      html = render(index_live)
      assert html =~ "Card updated successfully"
      assert html =~ "updated-namespace"
    end

    test "deletes card in listing", %{conn: conn, card: card} do
      {:ok, index_live, _html} = live(conn, ~p"/cards")

      assert index_live |> element("#cards-#{card.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cards-#{card.id}")
    end
  end

  describe "Show" do
    setup [:create_card]

    test "displays card", %{conn: conn, card: card} do
      {:ok, _show_live, html} = live(conn, ~p"/cards/#{card}")

      assert html =~ "Show Card"
      assert html =~ card.namespace
    end

    test "updates card and returns to show", %{conn: conn, card: card} do
      {:ok, show_live, _html} = live(conn, ~p"/cards/#{card}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/cards/#{card}/edit?return_to=show")

      assert render(form_live) =~ "Edit Card"

      assert form_live
             |> form("#card-form", card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#card-form", card: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/cards/#{card}")

      html = render(show_live)
      assert html =~ "Card updated successfully"
      assert html =~ "updated-namespace"
    end
  end
end
