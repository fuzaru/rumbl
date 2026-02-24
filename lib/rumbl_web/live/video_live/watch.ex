defmodule RumblWeb.VideoLive.Watch do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    video = Multimedia.get_video!(id)

    {:ok,
     socket
     |> assign(:page_title, video.title)
     |> assign(:video, video)
     |> assign(:annotations, Multimedia.list_annotations(video))
     |> assign(:user_token, user_token(socket.assigns.current_user))}
  end

  defp user_token(nil), do: nil
  defp user_token(user), do: Phoenix.Token.sign(RumblWeb.Endpoint, "user socket", user.id)

  def youtube_id(%Video{} = video), do: Video.youtube_id(video)

  def format_time(ms) when is_integer(ms) and ms >= 0 do
    total_seconds = div(ms, 1000)

    "#{div(total_seconds, 60)}:#{String.pad_leading(Integer.to_string(rem(total_seconds, 60)), 2, "0")}"
  end

  def format_time(_), do: "0:00"
end
