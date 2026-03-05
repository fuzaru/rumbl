defmodule RumblWeb.RingLive.Index do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia
  alias RumblWeb.RingLive.Index.{Invitations, RingManagement, RingPresence}
  alias RumblWeb.VideoLive.Index, as: VideoState
  import RumblWeb.RingLive.Components.MainContent
  import RumblWeb.RingLive.Components.Modals
  import RumblWeb.RingLive.Components.Presence
  import RumblWeb.RingLive.Components.Shell

  @video_events [
    "select_ring",
    "open_video",
    "back_to_rings",
    "add_annotation",
    "delete_workspace_video",
    "save_video_modal"
  ]

  @video_passthrough_events [
    "open_video_modal_new",
    "open_video_modal_edit",
    "close_video_modal",
    "validate_video_modal"
  ]

  @presence_synced_events ["save_video_modal", "respond_invitation"]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Home")
      |> assign(:active_panel, :rings)
      |> assign(:ring_filter, :all)
      |> assign(:panel_search_modal_open, false)
      |> assign(:panel_search_query, "")
      |> assign(:panel_search_global_videos, [])
      |> assign(:invite_modal_open, false)
      |> assign(:invite_modal_code, nil)
      |> assign(:rings, [])
      |> assign(:ring_members, [])
      |> assign(:active_ring_users, [])
      |> assign(:online_member_ids, MapSet.new())
      |> assign(:presence_topic, nil)
      |> assign(:presence_subscriptions, MapSet.new())
      |> assign(:selected_ring, nil)
      |> assign(:ring_videos, [])
      |> assign(:selected_video, nil)
      |> assign(:panel_search_form, to_form(%{"query" => ""}, as: :panel_search))
      |> Invitations.init_assigns()
      |> RingManagement.init_assigns()
      |> RingManagement.refresh_user_rings_and_video_state()
      |> sync_presence_state()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    panel_search_modal_open = params["search"] == "1"

    socket =
      socket
      |> apply_home_live_action(socket.assigns.live_action, params)
      |> assign(:page_title, page_title_for(socket.assigns.live_action, socket))
      |> assign(:panel_search_modal_open, panel_search_modal_open)
      |> Invitations.refresh_invitation_requests()
      |> sync_presence_state()

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", topic: topic}, socket) do
    {:noreply, RingPresence.handle_presence_diff(socket, topic)}
  end

  @impl true
  def handle_event("select_panel", %{"panel" => "rings"}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "My Rings")
     |> assign(:active_panel, :rings)
     |> VideoState.clear_ring_workspace()
     |> sync_presence_state()}
  end

  def handle_event("select_panel", %{"panel" => "requests"}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Invitation Requests")
     |> assign(:active_panel, :requests)
     |> VideoState.clear_ring_workspace()
     |> Invitations.refresh_invitation_requests()
     |> sync_presence_state()}
  end

  @impl true
  def handle_event("set_ring_filter", %{"filter" => "all"}, socket) do
    {:noreply, assign(socket, :ring_filter, :all)}
  end

  def handle_event("open_panel_search_modal", _params, socket) do
    {:noreply, assign(socket, :panel_search_modal_open, true)}
  end

  def handle_event("close_panel_search_modal", _params, socket) do
    {:noreply, assign(socket, :panel_search_modal_open, false)}
  end

  def handle_event("open_new_ring_modal", _params, socket) do
    {:noreply, RingManagement.open_new_modal(socket)}
  end

  def handle_event("close_new_ring_modal", _params, socket) do
    {:noreply, RingManagement.close_new_modal(socket)}
  end

  def handle_event("validate_new_ring", %{"ring" => ring_params}, socket) do
    {:noreply, RingManagement.validate_new_modal(socket, ring_params)}
  end

  def handle_event("save_new_ring", %{"ring" => ring_params}, socket) do
    RingManagement.save_new_ring(socket, ring_params)
  end

  def handle_event("open_join_ring_modal", _params, socket) do
    {:noreply, RingManagement.open_join_modal(socket)}
  end

  def handle_event("close_join_ring_modal", _params, socket) do
    {:noreply, RingManagement.close_join_modal(socket)}
  end

  def handle_event("validate_join_ring", %{"join_ring" => params}, socket) do
    {:noreply, RingManagement.validate_join_modal(socket, params)}
  end

  def handle_event("save_join_ring", %{"join_ring" => params}, socket) do
    RingManagement.save_join_ring(socket, params)
  end

  def handle_event(event, params, socket) when event in @video_passthrough_events do
    VideoState.dispatch_event(event, params, socket, socket.assigns.rings)
  end

  def handle_event("open_video_from_search", %{"video_slug" => video_slug}, socket) do
    case VideoState.dispatch_event(
           "open_video",
           %{"video_slug" => video_slug},
           socket,
           socket.assigns.rings
         ) do
      {:noreply, updated_socket} ->
        {:noreply, assign(updated_socket, :panel_search_modal_open, false)}

      other ->
        other
    end
  end

  def handle_event("search_panel_catalog", %{"panel_search" => %{"query" => query}}, socket) do
    trimmed_query = String.trim(query)

    {:noreply,
     socket
     |> assign(:panel_search_query, trimmed_query)
     |> assign(:panel_search_form, to_form(%{"query" => trimmed_query}, as: :panel_search))
     |> assign(:panel_search_global_videos, search_global_catalog_videos(socket, trimmed_query))}
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

  def handle_event("select_invite_ring", %{"invite_ring" => %{"ring_id" => ring_id}}, socket) do
    {:noreply, Invitations.select_invite_ring(socket, ring_id)}
  end

  def handle_event("search_invitees", %{"invite_search" => %{"query" => query}}, socket) do
    {:noreply, Invitations.search_invitees(socket, query)}
  end

  def handle_event("send_invite", %{"user_id" => user_id}, socket) do
    case Invitations.send_invite(socket, user_id) do
      {:ok, updated_socket, message} ->
        {:noreply, put_flash(updated_socket, :info, message)}

      {:error, updated_socket, message} ->
        {:noreply, put_flash(updated_socket, :error, message)}
    end
  end

  def handle_event(
        "respond_invitation",
        %{"invitation_id" => invitation_id, "action" => action},
        socket
      )
      when action in ["accept", "decline"] do
    case Invitations.respond_invitation(socket, invitation_id, action) do
      {:ok, updated_socket, message} ->
        {:noreply,
         updated_socket |> maybe_sync_presence("respond_invitation") |> put_flash(:info, message)}

      {:error, updated_socket, message} ->
        {:noreply, put_flash(updated_socket, :error, message)}
    end
  end

  def handle_event(event, params, socket) when event in @video_events do
    case VideoState.dispatch_event(event, params, socket, socket.assigns.rings) do
      {:noreply, updated_socket} ->
        {:noreply, maybe_sync_presence(updated_socket, event)}

      other ->
        other
    end
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

  defp search_global_catalog_videos(socket, query) do
    if socket.assigns.selected_ring do
      []
    else
      ring_ids = Enum.map(socket.assigns.rings, & &1.id)
      Multimedia.search_videos_for_rings(ring_ids, query)
    end
  end

  defp sync_presence_state(socket) do
    socket
    |> RingPresence.refresh_ring_members()
    |> RingPresence.sync_presence_topic()
  end

  defp maybe_sync_presence(socket, event) when event in @presence_synced_events do
    sync_presence_state(socket)
  end

  defp maybe_sync_presence(socket, _event), do: socket

  defp page_title_for(:rings, _socket), do: "My Rings"
  defp page_title_for(:requests, _socket), do: "Invitation Requests"

  defp page_title_for(:ring, socket) do
    case socket.assigns.selected_ring do
      %{name: name} when is_binary(name) and name != "" -> name
      _ -> "Ring"
    end
  end

  defp page_title_for(_live_action, socket), do: socket.assigns.page_title || "Rumbl"
end
