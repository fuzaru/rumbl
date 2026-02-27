defmodule RumblWeb.VideoLive.Show do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    video = Multimedia.get_video!(id)

    {:noreply,
     socket
     |> assign(:page_title, video.title)
     |> assign(:video, video)}
  end

  def clear_workspace(socket) do
    socket
    |> Phoenix.Component.assign(:selected_ring, nil)
    |> Phoenix.Component.assign(:ring_videos, [])
    |> Phoenix.Component.assign(:selected_video, nil)
  end

  def show_videos_panel(socket) do
    socket
    |> Phoenix.Component.assign(:active_panel, :videos)
    |> Phoenix.Component.assign(
      :my_videos,
      Multimedia.list_user_videos(socket.assigns.current_user)
    )
    |> clear_workspace()
  end

  def load_ring_workspace(socket, ring_id, rings, preferred_slug \\ nil) do
    ring = Enum.find(rings, &(&1.id == ring_id))
    videos = Multimedia.list_videos_for_ring(ring_id)
    selected_video = select_preferred_video(videos, socket.assigns.selected_video, preferred_slug)

    socket
    |> Phoenix.Component.assign(:active_panel, :rings)
    |> Phoenix.Component.assign(:selected_ring, ring)
    |> Phoenix.Component.assign(:ring_videos, videos)
    |> Phoenix.Component.assign(:selected_video, selected_video)
  end

  def select_video(socket, slug) do
    Phoenix.Component.assign(
      socket,
      :selected_video,
      Enum.find(socket.assigns.ring_videos, &(&1.slug == slug))
    )
  end

  def refresh_video_lists(socket, preferred_slug \\ nil) do
    my_videos = Multimedia.list_user_videos(socket.assigns.current_user)
    socket = Phoenix.Component.assign(socket, :my_videos, my_videos)

    if socket.assigns.selected_ring do
      videos = Multimedia.list_videos_for_ring(socket.assigns.selected_ring.id)

      selected_video =
        select_preferred_video(videos, socket.assigns.selected_video, preferred_slug)

      socket
      |> Phoenix.Component.assign(:ring_videos, videos)
      |> Phoenix.Component.assign(:selected_video, selected_video)
    else
      socket
    end
  end

  defp select_preferred_video(videos, current_video, preferred_slug) do
    cond do
      is_binary(preferred_slug) ->
        Enum.find(videos, &(&1.slug == preferred_slug)) || List.first(videos)

      current_video ->
        Enum.find(videos, &(&1.slug == current_video.slug)) || List.first(videos)

      true ->
        List.first(videos)
    end
  end
end
