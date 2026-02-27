defmodule RumblWeb.PageLive.Landing do
  use RumblWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      {:ok, redirect(socket, to: ~p"/rings")}
    else
      {:ok, assign(socket, :page_title, "Landing")}
    end
  end
end
