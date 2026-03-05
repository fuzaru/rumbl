defmodule RumblWeb.RingLive.Components.Helpers do
  def filter_rings(rings, ""), do: rings

  def filter_rings(rings, query) do
    normalized_query = String.downcase(query)

    Enum.filter(rings, fn ring ->
      String.contains?(String.downcase(ring.name), normalized_query)
    end)
  end

  def filter_ring_videos(videos, ""), do: videos

  def filter_ring_videos(videos, query) do
    normalized_query = String.downcase(query)

    Enum.filter(videos, fn video ->
      String.contains?(String.downcase(video.title), normalized_query)
    end)
  end

  def ring_name_by_id(rings, ring_id) do
    case Enum.find(rings, &(&1.id == ring_id)) do
      nil -> "Unknown Ring"
      ring -> ring.name
    end
  end
end
