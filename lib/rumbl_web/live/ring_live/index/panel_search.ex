defmodule RumblWeb.RingLive.Index.PanelSearch do
  import Phoenix.Component, only: [assign: 3, to_form: 2]

  alias Rumbl.Multimedia
  alias RumblWeb.VideoLive.Index, as: VideoState

  def open_modal(socket) do
    assign(socket, :panel_search_modal_open, true)
  end

  def close_modal(socket) do
    assign(socket, :panel_search_modal_open, false)
  end

  def search(socket, query) do
    trimmed_query = String.trim(query)

    socket
    |> assign(:panel_search_query, trimmed_query)
    |> assign(:panel_search_form, to_form(%{"query" => trimmed_query}, as: :panel_search))
    |> assign(:panel_search_global_videos, search_global_catalog_videos(socket, trimmed_query))
  end

  def open_video_result(socket, video_slug, rings) do
    {:noreply, updated_socket} =
      VideoState.dispatch_event(
        "open_video",
        %{"video_slug" => video_slug},
        socket,
        rings
      )

    assign(updated_socket, :panel_search_modal_open, false)
  end

  defp search_global_catalog_videos(socket, query) do
    if socket.assigns.selected_ring do
      []
    else
      ring_ids = Enum.map(socket.assigns.rings, & &1.id)
      Multimedia.search_videos_for_rings(ring_ids, query)
    end
  end
end
