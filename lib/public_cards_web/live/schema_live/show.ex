defmodule PublicCardsWeb.SchemaLive.Show do
  use PublicCardsWeb, :live_view

  alias PublicCards.Schema

  @impl true
  def mount(%{"id" => type_id}, _session, socket) do
    type_id = normalize_type_id(type_id)

    case Schema.get_type(type_id) do
      {:ok, type} ->
        {:ok, property_ids} = Schema.get_properties_for_type(type_id)

        properties =
          property_ids
          |> Enum.map(fn prop_id ->
            case Schema.get_property(prop_id) do
              {:ok, prop} ->
                %{
                  id: prop.id,
                  label: prop.label,
                  comment: prop.comment,
                  range: prop.range_includes
                }

              _ ->
                %{id: prop_id, label: nil, comment: nil, range: []}
            end
          end)
          |> Enum.sort_by(fn prop -> prop.label || prop.id end)

        {:ok,
         socket
         |> assign(:page_title, type.label || type.id)
         |> assign(:type, type)
         |> assign(:properties, properties)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Type not found: #{type_id}")
         |> push_navigate(to: ~p"/schema")}
    end
  end

  defp normalize_type_id(type_id) do
    type_id = String.replace(type_id, "%3A", ":")

    if String.starts_with?(type_id, "schema:") do
      type_id
    else
      "schema:#{type_id}"
    end
  end
end
