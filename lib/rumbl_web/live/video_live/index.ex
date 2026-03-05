defmodule RumblWeb.VideoLive.Index do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia
  alias Rumbl.Rings
  alias RumblWeb.VideoLive.{Modal, Show, Watch}

  @impl true
  def mount(_params, _session, socket) do
    videos = Multimedia.list_user_videos(socket.assigns.current_user)
    rings = Rings.list_user_rings(socket.assigns.current_user)
    ring_options = Rings.ring_options(rings)

    {:ok,
     socket
     |> assign(:page_title, "My Videos")
     |> assign(:rings, rings)
     |> assign(:videos_empty?, videos == [])
     |> stream(:videos, videos)
     |> init(ring_options)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_live_action(socket, :videos, params, socket.assigns.rings)}
  end

  @impl true
  def handle_event(event, params, socket) do
    dispatch_event(event, params, socket, socket.assigns.rings)
  end

  def init(socket, ring_options) do
    socket
    |> Modal.init_assigns(ring_options)
    |> Watch.init_assigns()
  end

  def clear_ring_workspace(socket) do
    socket
    |> Show.clear_workspace()
    |> Phoenix.Component.assign(:annotations, [])
    |> Watch.reset_annotation_form()
  end

  def show_videos_panel(socket), do: Show.show_videos_panel(socket)

  def apply_live_action(socket, :rings, _params, _rings) do
    socket
    |> Phoenix.Component.assign(:active_panel, :rings)
    |> clear_ring_workspace()
    |> Modal.close_modal()
  end

  def apply_live_action(socket, :ring, %{"ring_id" => ring_id} = params, rings) do
    socket
    |> Show.load_ring_workspace(ring_id, rings, params["video"])
    |> assign_annotations()
    |> Modal.close_modal()
  end

  def apply_live_action(socket, :videos, params, rings) do
    socket
    |> show_videos_panel()
    |> Modal.close_modal()
    |> apply_videos_query_params(params, rings)
  end

  def apply_live_action(socket, :requests, _params, _rings) do
    socket
    |> Phoenix.Component.assign(:active_panel, :requests)
    |> clear_ring_workspace()
    |> Modal.close_modal()
  end

  def apply_live_action(socket, _live_action, _params, _rings), do: socket

  def dispatch_event("delete", %{"id" => slug}, socket, _rings) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, slug)
    {:ok, _video} = Multimedia.delete_video(video)
    videos = Multimedia.list_user_videos(socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Video deleted successfully.")
     |> assign(:videos_empty?, videos == [])
     |> stream(:videos, videos, reset: true)}
  end

  def dispatch_event("select_ring", %{"ring_id" => ring_id}, socket, rings) do
    {:noreply, socket |> Show.load_ring_workspace(ring_id, rings) |> assign_annotations()}
  end

  def dispatch_event("open_video", %{"video_slug" => video_slug}, socket, _rings) do
    {:noreply, socket |> Show.select_video(video_slug) |> assign_annotations()}
  end

  def dispatch_event("back_to_rings", _params, socket, _rings) do
    {:noreply, clear_ring_workspace(socket)}
  end

  def dispatch_event("add_annotation", %{"annotation" => %{"body" => body}}, socket, _rings) do
    case Watch.add_annotation(socket, body) do
      {:ok, socket} -> {:noreply, socket |> assign_annotations()}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def dispatch_event("delete_workspace_video", %{"video_slug" => video_slug}, socket, _rings) do
    selected_video = Enum.find(socket.assigns.ring_videos, &(&1.slug == video_slug))
    current_user = socket.assigns.current_user

    cond do
      is_nil(selected_video) ->
        {:noreply, socket}

      is_nil(current_user) or selected_video.user_id != current_user.id ->
        {:noreply,
         Phoenix.LiveView.put_flash(socket, :error, "You can only delete your own videos.")}

      true ->
        {:ok, _video} = Multimedia.delete_video(selected_video)

        {:noreply,
         socket
         |> Show.refresh_video_lists()
         |> assign_annotations()
         |> Phoenix.LiveView.put_flash(:info, "Video deleted successfully")}
    end
  end

  def dispatch_event("delete_my_video", %{"video_slug" => video_slug}, socket, _rings) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, video_slug)
    {:ok, _video} = Multimedia.delete_video(video)

    {:noreply,
     socket
     |> Show.refresh_video_lists()
     |> assign_annotations()
     |> Phoenix.LiveView.put_flash(:info, "Video deleted successfully")}
  end

  def dispatch_event("open_video_modal_new", params, socket, _rings) do
    ring_id =
      params["ring_id"] ||
        if(socket.assigns.selected_ring, do: socket.assigns.selected_ring.id, else: "")

    {:noreply, Modal.open_new_modal(socket, ring_id)}
  end

  def dispatch_event("open_video_modal_edit", %{"video_slug" => video_slug}, socket, _rings) do
    {:noreply, Modal.open_edit_modal(socket, video_slug)}
  end

  def dispatch_event("close_video_modal", _params, socket, _rings) do
    {:noreply, socket |> Modal.close_modal() |> Phoenix.LiveView.push_patch(to: ~p"/videos")}
  end

  def dispatch_event("validate_video_modal", %{"video" => video_params}, socket, _rings) do
    {:noreply, Modal.validate_modal(socket, video_params)}
  end

  def dispatch_event("save_video_modal", %{"video" => video_params}, socket, _rings) do
    case Modal.save_modal(socket, video_params) do
      {:ok, _preferred_slug} ->
        videos = Multimedia.list_user_videos(socket.assigns.current_user)

        {:noreply,
         socket
         |> assign(:videos_empty?, videos == [])
         |> stream(:videos, videos, reset: true)
         |> Modal.close_modal()
         |> Phoenix.LiveView.push_patch(to: ~p"/videos")
         |> Phoenix.LiveView.put_flash(:info, "Video saved successfully")}

      {:error, socket} ->
        {:noreply, socket}
    end
  end

  defp apply_videos_query_params(socket, params, rings) do
    cond do
      params["modal"] == "new" ->
        Modal.open_new_modal(socket, params["ring"] || "")

      params["modal"] == "edit" and is_binary(params["video"]) ->
        Modal.open_edit_modal(socket, params["video"])

      is_binary(params["ring"]) ->
        socket
        |> Show.load_ring_workspace(params["ring"], rings, params["video"])
        |> assign_annotations()

      true ->
        socket
    end
  end

  defp assign_annotations(socket) do
    Phoenix.Component.assign(
      socket,
      :annotations,
      Watch.annotations_for_video(socket.assigns.selected_video)
    )
  end
end
