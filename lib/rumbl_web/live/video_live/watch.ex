defmodule RumblWeb.VideoLive.Watch do
  alias Rumbl.Multimedia
  alias Rumbl.Multimedia.Video

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
end
