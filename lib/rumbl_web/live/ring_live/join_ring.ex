defmodule RumblWeb.RingLive.JoinRing do
  use RumblWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Join Ring")}
  end
end
