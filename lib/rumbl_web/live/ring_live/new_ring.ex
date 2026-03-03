defmodule RumblWeb.RingLive.NewRing do
  use RumblWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "New Ring")}
  end
end
