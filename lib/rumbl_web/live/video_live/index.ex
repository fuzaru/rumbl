defmodule RumblWeb.VideoLive.Index do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "My Videos")
     |> assign(:videos_empty?, true)
     |> stream(:videos, [])}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    videos = Multimedia.list_user_videos(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:videos_empty?, videos == [])
     |> stream(:videos, videos, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => slug}, socket) do
    video = Multimedia.get_user_video!(socket.assigns.current_user, slug)
    {:ok, _video} = Multimedia.delete_video(video)

    {:noreply,
     socket
     |> stream_delete(:videos, video)
     |> put_flash(:info, "Video deleted successfully")}
  end
end
