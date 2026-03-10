defmodule RumblWeb.RingLive.Components.Helpers do
  defp filter_by(items, "", _extractor), do: items

  defp filter_by(items, query, extractor) do
    normalized_query = String.downcase(query)

    Enum.filter(items, fn item ->
      item
      |> extractor.()
      |> String.downcase()
      |> String.contains?(normalized_query)
    end)
  end

  def filter_rings(rings, query), do: filter_by(rings, query, & &1.name)
  def filter_ring_videos(videos, query), do: filter_by(videos, query, & &1.title)

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
    |> Enum.sort_by(fn group -> String.downcase(group.category) end)
  end

  def ring_name_by_id(rings, ring_id) do
    Enum.find_value(rings, "Unknown Ring", fn
      %{id: ^ring_id, name: name} -> name
      _ -> nil
    end)
  end

  def short_annotation_preview(text, max_length \\ 80)

  def short_annotation_preview(text, max_length)
      when is_binary(text) and is_integer(max_length) and max_length > 0 do
    normalized_text = text |> String.trim() |> String.replace(~r/\s+/, " ")

    if String.length(normalized_text) > max_length,
      do: String.slice(normalized_text, 0, max_length) <> "…",
      else: normalized_text
  end

  def short_annotation_preview(_text, _max_length), do: ""
end
