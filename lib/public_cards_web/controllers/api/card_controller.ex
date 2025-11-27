defmodule PublicCardsWeb.Api.CardController do
  use PublicCardsWeb, :controller

  alias PublicCards.Cards

  def show(conn, %{"id" => id}) do
    case Cards.get_card(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Card not found"})

      card ->
        conn
        |> put_resp_content_type("application/ld+json")
        |> json(card_to_json_ld(card))
    end
  end

  defp card_to_json_ld(card) do
    %{
      "@context" => "https://schema.org",
      "@type" => "CreativeWork",
      "@id" => "#{PublicCardsWeb.Endpoint.url()}/cards/#{card.id}",
      "name" => card.title,
      "version" => card.version,
      "dateModified" => card.updated_at,
      "author" => %{
        "@type" => "Person",
        "email" => card.owner_email
      },
      "license" => license_url(card.terms),
      "mainEntity" => card.content,
      "identifier" => %{
        "@type" => "PropertyValue",
        "propertyID" => "content_hash",
        "value" => card.content_hash
      }
    }
  end

  defp license_url("cc-by"), do: "https://creativecommons.org/licenses/by/4.0/"
  defp license_url("cc0"), do: "https://creativecommons.org/publicdomain/zero/1.0/"
  defp license_url("all-rights-reserved"), do: nil
  defp license_url(url) when is_binary(url), do: url
  defp license_url(_), do: nil
end
