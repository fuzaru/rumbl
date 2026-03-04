defmodule RumblWeb.PageLive.Home do
  use RumblWeb, :live_view

  alias Rumbl.Rings
  alias RumblWeb.VideoLive.Index, as: VideoState

  @invitation_samples [
    %{id: "alex", requester: "Alex", ring: "Alpha Ring", note: "Wants to collaborate"},
    %{id: "jo", requester: "Jo", ring: "Launch Circle", note: "Requested access yesterday"}
  ]

  @video_events [
    "select_ring",
    "open_video",
    "back_to_rings",
    "add_annotation",
    "delete_workspace_video"
  ]

  @impl true
  def mount(_params, _session, socket) do
    rings = Rings.list_user_rings(socket.assigns.current_user)
    ring_options = Enum.map(rings, fn ring -> {ring.name, ring.id} end)

    {:ok,
     socket
     |> assign(:page_title, "Home")
     |> assign(:active_panel, :rings)
     |> assign(:ring_filter, :all)
     |> assign(:invite_modal_open, false)
     |> assign(:invite_modal_code, nil)
     |> assign(:rings, rings)
     |> assign(:invitation_requests, @invitation_samples)
     |> assign(:selected_ring, nil)
     |> assign(:ring_videos, [])
     |> assign(:selected_video, nil)
     |> VideoState.init(ring_options)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_home_live_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("select_panel", %{"panel" => "rings"}, socket) do
    {:noreply,
     socket
     |> assign(:active_panel, :rings)
     |> VideoState.clear_ring_workspace()}
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

  def handle_event("show_invite_code", _params, socket) do
    ring = socket.assigns.selected_ring

    if ring && socket.assigns.current_user && ring.owner_id == socket.assigns.current_user.id do
      {:noreply,
       socket
       |> assign(:invite_modal_open, true)
       |> assign(:invite_modal_code, ring.invite_code)}
    else
      {:noreply, put_flash(socket, :error, "Only the ring owner can view the invite code.")}
    end
  end

  def handle_event("close_invite_modal", _params, socket) do
    {:noreply, socket |> assign(:invite_modal_open, false) |> assign(:invite_modal_code, nil)}
  end

  def handle_event(event, params, socket) when event in @video_events do
    VideoState.handle_event(event, params, socket, socket.assigns.rings)
  end

  defp apply_home_live_action(socket, :rings, _params) do
    VideoState.apply_live_action(socket, :rings, %{}, socket.assigns.rings)
  end

  defp apply_home_live_action(socket, :ring, %{"ring_id" => ring_id} = params) do
    VideoState.apply_live_action(
      socket,
      :ring,
      %{"ring_id" => ring_id, "video" => params["video"]},
      socket.assigns.rings
    )
  end

  defp apply_home_live_action(socket, :requests, _params) do
    VideoState.apply_live_action(socket, :requests, %{}, socket.assigns.rings)
  end

  defp apply_home_live_action(socket, _live_action, _params), do: socket
end
