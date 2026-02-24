defmodule RumblWeb.VideoLive.Show do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    video = Multimedia.get_video!(id)

    {:ok,
     socket
     |> assign(:page_title, video.title)
     |> assign(:video, video)}
  end
end
