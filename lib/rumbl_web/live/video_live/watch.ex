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
    |> put_annotation_form("", "")
  end

  def annotations_for_video(nil), do: []

  def annotations_for_video(video) do
    Multimedia.list_annotations(video)
    |> Enum.sort_by(& &1.at)
    |> Enum.map(fn annotation ->
      %{
        id: annotation.id,
        at: annotation.at,
        author: annotation.user.name,
        body: annotation.body
      }
    end)
  end

  def reset_annotation_form(socket) do
    put_annotation_form(socket, "", "")
  end

  def add_annotation(socket, at, body) do
    trimmed_at = String.trim(at || "")
    trimmed_body = String.trim(body || "")

    cond do
      trimmed_body == "" ->
        {:error,
         socket
         |> put_annotation_form(trimmed_at, trimmed_body)
         |> Phoenix.LiveView.put_flash(:error, "Message is required.")}

      is_nil(socket.assigns.current_user) or is_nil(socket.assigns.selected_video) ->
        {:error,
         Phoenix.LiveView.put_flash(socket, :error, "Select a video before adding annotations.")}

      true ->
        case parse_timestamp_to_ms(trimmed_at) do
          {:ok, at_ms} ->
            case Multimedia.annotate_video(
                   socket.assigns.current_user,
                   socket.assigns.selected_video.id,
                   %{
                     "body" => trimmed_body,
                     "at" => at_ms
                   }
                 ) do
              {:ok, _annotation} ->
                {:ok, reset_annotation_form(socket)}

              {:error, changeset} ->
                {:error,
                 Phoenix.LiveView.put_flash(
                   socket,
                   :error,
                   annotation_error_message(changeset)
                 )}
            end

          :error ->
            {:error,
             socket
             |> put_annotation_form(trimmed_at, trimmed_body)
             |> Phoenix.LiveView.put_flash(
               :error,
               "Timestamp is required and must be in m:ss or h:mm:ss format."
             )}
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

  def parse_timestamp_to_ms(timestamp) when is_binary(timestamp) do
    case String.split(timestamp, ":") do
      [minutes, seconds] ->
        with {minutes_int, ""} <- Integer.parse(minutes),
             {seconds_int, ""} <- Integer.parse(seconds),
             true <- minutes_int >= 0 and seconds_int >= 0 and seconds_int < 60 do
          {:ok, (minutes_int * 60 + seconds_int) * 1000}
        else
          _ -> :error
        end

      [hours, minutes, seconds] ->
        with {hours_int, ""} <- Integer.parse(hours),
             {minutes_int, ""} <- Integer.parse(minutes),
             {seconds_int, ""} <- Integer.parse(seconds),
             true <-
               hours_int >= 0 and minutes_int >= 0 and minutes_int < 60 and seconds_int >= 0 and
                 seconds_int < 60 do
          {:ok, (hours_int * 3600 + minutes_int * 60 + seconds_int) * 1000}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def parse_timestamp_to_ms(_), do: :error

  defp annotation_error_message(changeset) do
    body_errors = Keyword.get_values(changeset.errors, :body)

    if Enum.any?(body_errors, fn {message, _opts} ->
         String.contains?(message, "should be at most")
       end) do
      "Message is too long (maximum 255 characters)."
    else
      "Could not add annotation."
    end
  end

  defp build_user_token(nil), do: nil

  defp build_user_token(user) do
    Phoenix.Token.sign(RumblWeb.Endpoint, "user socket", user.id)
  end

  defp put_annotation_form(socket, at, body) do
    Phoenix.Component.assign(
      socket,
      :annotation_form,
      Phoenix.Component.to_form(%{"at" => at, "body" => body}, as: :annotation)
    )
  end
end
