defmodule RumblWeb.VideoLive.Index do
  alias Rumbl.Multimedia
  alias RumblWeb.VideoLive.{Form, Show, Watch}

  def init(socket, ring_options) do
    socket
    |> Form.init_assigns(ring_options)
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
    |> Form.close_modal()
  end

  def apply_live_action(socket, :ring, %{"ring_id" => ring_id} = params, rings) do
    socket
    |> Show.load_ring_workspace(ring_id, rings, params["video"])
    |> assign_annotations()
    |> Form.close_modal()
  end

  def apply_live_action(socket, :videos, params, rings) do
    socket
    |> show_videos_panel()
    |> Form.close_modal()
    |> apply_videos_query_params(params, rings)
  end

  def apply_live_action(socket, :requests, _params, _rings) do
    socket
    |> Phoenix.Component.assign(:active_panel, :requests)
    |> clear_ring_workspace()
    |> Form.close_modal()
  end

  def apply_live_action(socket, _live_action, _params, _rings), do: socket

  def handle_event("select_ring", %{"ring_id" => ring_id}, socket, rings) do
    {:noreply, socket |> Show.load_ring_workspace(ring_id, rings) |> assign_annotations()}
  end

  def handle_event("open_video", %{"video_slug" => video_slug}, socket, _rings) do
    {:noreply, socket |> Show.select_video(video_slug) |> assign_annotations()}
  end

  def handle_event("back_to_rings", _params, socket, _rings) do
    {:noreply, clear_ring_workspace(socket)}
  end

  def handle_event("add_annotation", %{"annotation" => %{"body" => body}}, socket, _rings) do
    case Watch.add_annotation(socket, body) do
      {:ok, socket} -> {:noreply, socket |> assign_annotations()}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def handle_event("delete_workspace_video", %{"video_slug" => video_slug}, socket, _rings) do
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

  def handle_event("delete_my_video", %{"video_slug" => video_slug}, socket, _rings) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, video_slug)
    {:ok, _video} = Multimedia.delete_video(video)

    {:noreply,
     socket
     |> Show.refresh_video_lists()
     |> assign_annotations()
     |> Phoenix.LiveView.put_flash(:info, "Video deleted successfully")}
  end

  def handle_event("open_video_modal_new", params, socket, _rings) do
    ring_id =
      params["ring_id"] ||
        if(socket.assigns.selected_ring, do: socket.assigns.selected_ring.id, else: "")

    {:noreply, Form.open_new_modal(socket, ring_id)}
  end

  def handle_event("open_video_modal_edit", %{"video_slug" => video_slug}, socket, _rings) do
    {:noreply, Form.open_edit_modal(socket, video_slug)}
  end

  def handle_event("close_video_modal", _params, socket, _rings) do
    {:noreply, Form.close_modal(socket)}
  end

  def handle_event("validate_video_modal", %{"video" => video_params}, socket, _rings) do
    {:noreply, Form.validate_modal(socket, video_params)}
  end

  def handle_event("save_video_modal", %{"video" => video_params}, socket, _rings) do
    case Form.save_modal(socket, video_params) do
      {:ok, preferred_slug} ->
        {:noreply,
         socket
         |> Show.refresh_video_lists(preferred_slug)
         |> assign_annotations()
         |> Form.close_modal()
         |> Phoenix.LiveView.put_flash(:info, "Video saved successfully")}

      {:error, socket} ->
        {:noreply, socket}
    end
  end

  defp apply_videos_query_params(socket, params, rings) do
    cond do
      params["modal"] == "new" ->
        Form.open_new_modal(socket, params["ring"] || "")

      params["modal"] == "edit" and is_binary(params["video"]) ->
        Form.open_edit_modal(socket, params["video"])

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
