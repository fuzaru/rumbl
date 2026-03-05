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

  def grouped_ring_videos(videos, all_categories, query) do
    videos_by_category_id =
      videos
      |> filter_ring_videos(query)
      |> Enum.reject(&is_nil(&1.category))
      |> Enum.group_by(& &1.category.id)

    all_categories
    |> Enum.map(fn category ->
      %{
        id: category.id,
        category: category.name,
        videos: Map.get(videos_by_category_id, category.id, [])
      }
    end)
    |> Enum.sort_by(&category_sort_key/1)
  end

  def ring_name_by_id(rings, ring_id) do
    case Enum.find(rings, &(&1.id == ring_id)) do
      nil -> "Unknown Ring"
      ring -> ring.name
    end
  end

  defp category_sort_key(%{category: category_name}), do: {0, String.downcase(category_name)}
end
