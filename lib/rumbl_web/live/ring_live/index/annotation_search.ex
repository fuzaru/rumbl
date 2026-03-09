defmodule RumblWeb.RingLive.Index.AnnotationSearch do
  import Phoenix.Component, only: [assign: 3, to_form: 2]

  alias RumblWeb.VideoLive.Index, as: VideoState
  alias RumblWeb.VideoLive.Watch

  def open_modal(socket) do
    annotation_entries = ring_annotation_entries(socket)

    socket
    |> assign(:annotation_search_modal_open, true)
    |> assign(:annotation_search_query, "")
    |> assign(:annotation_search_form, to_form(%{"query" => ""}, as: :annotation_search))
    |> assign(:annotation_search_results, annotation_entries)
  end

  def search(socket, query) do
    trimmed_query = String.trim(query)
    annotation_entries = ring_annotation_entries(socket)

    socket
    |> assign(:annotation_search_query, trimmed_query)
    |> assign(
      :annotation_search_form,
      to_form(%{"query" => trimmed_query}, as: :annotation_search)
    )
    |> assign(:annotation_search_results, filter_annotations(annotation_entries, trimmed_query))
  end

  def select_result(socket, annotation_id, rings) do
    annotation_entry =
      find_annotation_by_id(socket.assigns[:annotation_search_results] || [], annotation_id)

    if annotation_entry do
      {:noreply, updated_socket} =
        VideoState.dispatch_event(
          "open_video",
          %{"video_slug" => annotation_entry.video_slug},
          socket,
          rings
        )

      selected_annotation =
        find_annotation_by_id(updated_socket.assigns[:annotations] || [], annotation_id)

      seconds = div(annotation_entry.at, 1000)

      updated_socket
      |> assign(:annotation_search_modal_open, false)
      |> assign(:selected_annotation, selected_annotation)
      |> assign(:player_time_seconds, seconds)
      |> Phoenix.LiveView.push_event("seek_video", %{seconds: seconds})
    else
      socket
    end
  end

  defp filter_annotations(annotations, ""), do: annotations

  defp filter_annotations(annotations, query) do
    normalized_query = String.downcase(query)

    Enum.filter(annotations, fn annotation ->
      String.contains?(String.downcase(annotation.body || ""), normalized_query) or
        String.contains?(String.downcase(annotation.author || ""), normalized_query) or
        String.contains?(String.downcase(annotation.video_title || ""), normalized_query) or
        String.contains?(String.downcase(annotation.category_name || ""), normalized_query) or
        String.contains?(String.downcase(Watch.format_time(annotation.at)), normalized_query)
    end)
  end

  defp ring_annotation_entries(socket) do
    socket.assigns.ring_videos
    |> Enum.flat_map(fn video ->
      video_annotations = Watch.annotations_for_video(video)

      Enum.map(video_annotations, fn annotation ->
        annotation
        |> Map.put(:video_slug, video.slug)
        |> Map.put(:video_title, video.title)
        |> Map.put(
          :category_name,
          if(video.category, do: video.category.name, else: "Uncategorized")
        )
      end)
    end)
    |> Enum.sort_by(& &1.at)
  end

  defp find_annotation_by_id(annotations, annotation_id) do
    with {id, ""} <- Integer.parse(annotation_id) do
      Enum.find(annotations, &(&1.id == id))
    else
      _ -> nil
    end
  end
end
