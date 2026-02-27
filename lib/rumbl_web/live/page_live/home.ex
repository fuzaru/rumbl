defmodule RumblWeb.PageLive.Home do
  use RumblWeb, :live_view

  alias RumblWeb.VideoLive.Index, as: VideoState

  @ring_samples [
    %{id: "alpha", name: "Alpha Ring", members: 8, status: "Active"},
    %{id: "focus", name: "Focus Ring", members: 3, status: "Planning"},
    %{id: "launch", name: "Launch Circle", members: 11, status: "Live"}
  ]

  @invitation_samples [
    %{id: "alex", requester: "Alex", ring: "Alpha Ring", note: "Wants to collaborate"},
    %{id: "jo", requester: "Jo", ring: "Launch Circle", note: "Requested access yesterday"}
  ]

  @ring_options Enum.map(@ring_samples, fn ring -> {ring.name, ring.id} end)

  @video_events [
    "select_ring",
    "open_video",
    "back_to_rings",
    "add_annotation",
    "delete_workspace_video",
    "delete_my_video",
    "open_video_modal_new",
    "open_video_modal_edit",
    "close_video_modal",
    "validate_video_modal",
    "save_video_modal"
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:active_panel, :rings)
     |> assign(:ring_filter, :all)
     |> assign(:rings, @ring_samples)
     |> assign(:invitation_requests, @invitation_samples)
     |> assign(:selected_ring, nil)
     |> assign(:ring_videos, [])
     |> assign(:selected_video, nil)
     |> VideoState.init(@ring_options)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     VideoState.apply_live_action(socket, socket.assigns.live_action, params, @ring_samples)}
  end

  @impl true
  def handle_event("select_panel", %{"panel" => "rings"}, socket) do
    {:noreply,
     socket
     |> assign(:active_panel, :rings)
     |> VideoState.clear_ring_workspace()}
  end

  def handle_event("select_panel", %{"panel" => "videos"}, socket) do
    {:noreply, VideoState.show_videos_panel(socket)}
  end

  def handle_event("select_panel", %{"panel" => "requests"}, socket) do
    {:noreply,
     socket
     |> assign(:active_panel, :requests)
     |> VideoState.clear_ring_workspace()}
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

  def handle_event("join_ring", _params, socket) do
    {:noreply, put_flash(socket, :info, "Join ring flow is coming soon.")}
  end

  def handle_event(event, params, socket) when event in @video_events do
    VideoState.handle_event(event, params, socket, @ring_samples)
  end
end
