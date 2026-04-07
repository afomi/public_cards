defmodule PublicCardsWeb.Api.EventsController do
  @moduledoc """
  API endpoint for syncing events across nodes.

  This is the foundation for the distributed protocol. Nodes can:
  1. Fetch events since a known hash
  2. Filter by schema types
  3. Paginate results

  ## Example

      GET /api/events
      GET /api/events?since=abc123
      GET /api/events?types[]=schema:Person&types[]=schema:Organization
      GET /api/events?since=abc123&limit=50
  """
  use PublicCardsWeb, :controller

  alias PublicCards.Cards

  @doc """
  Returns events for sync.

  Query params:
  - `since` - Hash of last known event (returns events after this)
  - `types[]` - Schema types to filter by
  - `limit` - Maximum events to return (default 100)
  """
  def index(conn, params) do
    opts = [
      since: params["since"],
      types: params["types"],
      limit: parse_limit(params["limit"])
    ]

    events = Cards.get_events_for_sync(opts)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{
      events: Enum.map(events, &event_to_json/1),
      count: length(events),
      # Include the hash of the last event for pagination
      next_since: List.last(events) |> get_hash()
    })
  end

  defp parse_limit(nil), do: 100

  defp parse_limit(limit) when is_binary(limit) do
    case Integer.parse(limit) do
      {num, ""} -> num |> max(1) |> min(1000)
      _ -> 100
    end
  end

  defp parse_limit(limit) when is_integer(limit), do: min(limit, 1000)

  defp get_hash(nil), do: nil
  defp get_hash(event), do: event.hash

  defp event_to_json(event) do
    %{
      id: event.id,
      card_id: event.card_id,
      hash: event.hash,
      prev_event_id: event.prev_event_id,
      op: event.op,
      field: event.field,
      value: event.value,
      author: event.author,
      timestamp: event.inserted_at
    }
  end
end
