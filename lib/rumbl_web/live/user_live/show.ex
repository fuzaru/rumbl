defmodule RumblWeb.UserLive.Show do
  use RumblWeb, :live_view

  alias Rumbl.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "User")
     |> assign(:user, Accounts.get_user!(id))}
  end
end
