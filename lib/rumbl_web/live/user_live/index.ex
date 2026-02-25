defmodule RumblWeb.UserLive.Index do
  use RumblWeb, :live_view

  alias Rumbl.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Users")
     |> assign(:users, Accounts.list_users())}
  end
end
