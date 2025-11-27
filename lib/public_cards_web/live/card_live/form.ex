defmodule PublicCardsWeb.CardLive.Form do
  use PublicCardsWeb, :live_view

  alias PublicCards.Cards
  alias PublicCards.Cards.Card

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage card records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="card-form" phx-change="validate" phx-submit="save">
        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:namespace]} type="text" label="Namespace" placeholder="my-namespace" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="my-card" />
        </div>
        <.input field={@form[:title]} type="text" label="Title" />
        <div class="grid grid-cols-2 gap-4">
          <.input
            field={@form[:card_type]}
            type="select"
            label="Card Type"
            options={["profile", "project", "jurisdiction", "trading"]}
          />
          <.input
            field={@form[:terms]}
            type="select"
            label="Terms"
            options={["cc-by", "cc0", "all-rights-reserved"]}
          />
        </div>
        <.input field={@form[:owner_email]} type="email" label="Owner Email" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={["draft", "published"]}
        />
        <div class="mb-4">
          <label class="block text-sm font-medium text-slate-700 mb-1">Content (JSON)</label>
          <textarea
            name="card[content_json]"
            rows="10"
            class="w-full px-3 py-2 border border-slate-300 rounded text-sm font-mono bg-white focus:outline-none focus:ring-2 focus:ring-slate-500 focus:border-slate-500"
            placeholder='{"front": {}, "back": {}}'
          >{@content_json}</textarea>
        </div>
        <footer class="mt-6 pt-6 border-t border-slate-200 flex gap-3">
          <.button phx-disable-with="Saving..." variant="primary">Save Card</.button>
          <.button navigate={return_path(@return_to, @card)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    card = Cards.get_card!(id)
    content_json = Jason.encode!(card.content || %{}, pretty: true)

    socket
    |> assign(:page_title, "Edit Card")
    |> assign(:card, card)
    |> assign(:content_json, content_json)
    |> assign(:form, to_form(Cards.change_card(card)))
  end

  defp apply_action(socket, :new, _params) do
    card = %Card{}
    default_content = %{"front" => %{}, "back" => %{}}

    socket
    |> assign(:page_title, "New Card")
    |> assign(:card, card)
    |> assign(:content_json, Jason.encode!(default_content, pretty: true))
    |> assign(:form, to_form(Cards.change_card(card)))
  end

  @impl true
  def handle_event("validate", %{"card" => card_params}, socket) do
    {card_params, content_json} = parse_content_json(card_params)
    changeset = Cards.change_card(socket.assigns.card, card_params)

    {:noreply,
     socket
     |> assign(:content_json, content_json)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"card" => card_params}, socket) do
    {card_params, _content_json} = parse_content_json(card_params)
    save_card(socket, socket.assigns.live_action, card_params)
  end

  defp parse_content_json(card_params) do
    content_json = Map.get(card_params, "content_json", "{}")

    content =
      case Jason.decode(content_json) do
        {:ok, parsed} -> parsed
        {:error, _} -> %{}
      end

    card_params =
      card_params
      |> Map.delete("content_json")
      |> Map.put("content", content)

    {card_params, content_json}
  end

  defp save_card(socket, :edit, card_params) do
    case Cards.update_card(socket.assigns.card, card_params) do
      {:ok, card} ->
        {:noreply,
         socket
         |> put_flash(:info, "Card updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, card))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_card(socket, :new, card_params) do
    case Cards.create_card(card_params) do
      {:ok, card} ->
        {:noreply,
         socket
         |> put_flash(:info, "Card created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, card))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _card), do: ~p"/cards"
  defp return_path("show", card), do: ~p"/cards/#{card}"
end
