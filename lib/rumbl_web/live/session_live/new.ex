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
end
