defmodule RumblWeb.PageLive.Home do
  use RumblWeb, :live_view

  @ring_samples [
    %{id: "alpha", name: "Alpha Ring", members: 8, status: "Active"},
    %{id: "focus", name: "Focus Ring", members: 3, status: "Planning"},
    %{id: "launch", name: "Launch Circle", members: 11, status: "Live"}
  ]

  @invitation_samples [
    %{id: "alex", requester: "Alex", ring: "Alpha Ring", note: "Wants to collaborate"},
    %{id: "jo", requester: "Jo", ring: "Launch Circle", note: "Requested access yesterday"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:active_panel, :rings)
     |> assign(:ring_filter, :all)
     |> assign(:rings, @ring_samples)
     |> assign(:invitation_requests, @invitation_samples)}
  end

  @impl true
  def handle_event("select_panel", %{"panel" => "rings"}, socket) do
    {:noreply, assign(socket, :active_panel, :rings)}
  end

  def handle_event("select_panel", %{"panel" => "requests"}, socket) do
    {:noreply, assign(socket, :active_panel, :requests)}
  end

  @impl true
  def handle_event("set_ring_filter", %{"filter" => "all"}, socket) do
    {:noreply, assign(socket, :ring_filter, :all)}
  end

  def handle_event("new_ring", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "New ring creation flow is coming soon.")
     |> assign(:ring_filter, :all)}
  end
end
