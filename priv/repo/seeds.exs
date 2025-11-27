# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Or reset and seed in one command:
#
#     mix ecto.reset
#

alias PublicCards.Cards

# Sample cards for development

# Profile card
{:ok, _profile} =
  Cards.create_card(%{
    namespace: "ryan",
    slug: "profile",
    card_type: "profile",
    title: "Ryan's Profile",
    content: %{
      "front" => %{
        "name" => "Ryan",
        "tagline" => "Building the open web"
      },
      "back" => %{
        "bio" => "Developer and civic tech enthusiast.",
        "links" => [
          %{"label" => "GitHub", "url" => "https://github.com/ryan"},
          %{"label" => "Website", "url" => "https://example.com"}
        ]
      }
    },
    terms: "cc-by",
    owner_email: "ryan@example.com",
    status: "published"
  })

# Jurisdiction card (for Jurisdictional.org use case)
{:ok, _jurisdiction} =
  Cards.create_card(%{
    namespace: "jurisdictional",
    slug: "san-francisco",
    card_type: "jurisdiction",
    title: "City and County of San Francisco",
    content: %{
      "front" => %{
        "name" => "San Francisco",
        "type" => "City and County",
        "state" => "California",
        "population" => 874_961
      },
      "back" => %{
        "mayor" => "London Breed",
        "website" => "https://sf.gov",
        "established" => 1850
      }
    },
    terms: "cc0",
    owner_email: "admin@jurisdictional.org",
    status: "published"
  })

# Project card
{:ok, _project} =
  Cards.create_card(%{
    namespace: "civic-studio",
    slug: "public-cards",
    card_type: "project",
    title: "Public Cards",
    content: %{
      "front" => %{
        "name" => "Public Cards",
        "tagline" => "Rekindling the creative web"
      },
      "back" => %{
        "description" => "An open protocol for structured, public data objects.",
        "status" => "In Development",
        "repository" => "https://github.com/example/public-cards"
      }
    },
    terms: "cc-by",
    owner_email: "hello@civicstudio.org",
    status: "published"
  })

IO.puts("Seeded #{length(PublicCards.Cards.list_cards())} cards")
