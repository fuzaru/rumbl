defmodule RumblWeb.UserLive.Show do
  use RumblWeb, :live_view

  alias Rumbl.Accounts
  alias Rumbl.Rings

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    profile_user = Accounts.get_user!(id)
    current_user = socket.assigns.current_user

    if Rings.share_ring?(current_user, profile_user) do
      {:ok,
       socket
       |> assign(:page_title, profile_user.name)
       |> assign(:user, profile_user)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You can only view profiles of users in the same ring.")
       |> redirect(to: ~p"/rings")}
    end
  end
end
