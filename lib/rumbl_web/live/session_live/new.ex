defmodule RumblWeb.SessionLive.New do
  use RumblWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{}, as: :session)

    {:ok,
     socket
     |> assign(:page_title, "Log In")
     |> assign(:form, form)}
  end

  @impl true
  def handle_event("validate", %{"session" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :session))}
  end
end
