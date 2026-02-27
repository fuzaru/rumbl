defmodule RumblWeb.VideoLive.Watch do
  use RumblWeb, :live_view

  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :user_token, build_user_token(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    video = Multimedia.get_video!(id)
    annotations = Multimedia.list_annotations(video)

    {:noreply,
     socket
     |> assign(:page_title, video.title)
     |> assign(:video, video)
     |> assign(:annotations, annotations)}
  end

  def init_assigns(socket) do
    socket
    |> Phoenix.Component.assign(:annotations, [])
    |> Phoenix.Component.assign(
      :annotation_form,
      Phoenix.Component.to_form(%{"body" => ""}, as: :annotation)
    )
  end

  def annotations_for_video(nil), do: []

  def annotations_for_video(video) do
    Multimedia.list_annotations(video)
    |> Enum.map(fn annotation ->
      %{id: annotation.id, author: annotation.user.name, body: annotation.body}
    end)
  end

  def reset_annotation_form(socket) do
    Phoenix.Component.assign(
      socket,
      :annotation_form,
      Phoenix.Component.to_form(%{"body" => ""}, as: :annotation)
    )
  end

  def add_annotation(socket, body) do
    trimmed_body = String.trim(body)

    cond do
      trimmed_body == "" ->
        {:error, reset_annotation_form(socket)}

      is_nil(socket.assigns.current_user) or is_nil(socket.assigns.selected_video) ->
        {:error,
         Phoenix.LiveView.put_flash(socket, :error, "Select a video before adding annotations.")}

      true ->
        case Multimedia.annotate_video(
               socket.assigns.current_user,
               socket.assigns.selected_video.id,
               %{
                 "body" => trimmed_body,
                 "at" => 0
               }
             ) do
          {:ok, _annotation} ->
            {:ok, reset_annotation_form(socket)}

          {:error, _changeset} ->
            {:error, Phoenix.LiveView.put_flash(socket, :error, "Could not add annotation.")}
        end
    end
  end

  def youtube_id(%Video{} = video), do: Video.youtube_id(video)

  def format_time(ms) when is_integer(ms) and ms >= 0 do
    total_seconds = div(ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end

  def format_time(_), do: "0:00"

  defp build_user_token(nil), do: nil

  defp build_user_token(user) do
    Phoenix.Token.sign(RumblWeb.Endpoint, "user socket", user.id)
  end
end
