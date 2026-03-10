defmodule RumblWeb.RingLive.Components.Helpers do
  defp filter_by(items, "", _fun), do: items

  defp filter_by(items, query, fun) do
    q = String.downcase(query)
    Enum.filter(items, &String.contains?(String.downcase(fun.(&1)), q))
  end

  def filter_rings(rings, query), do: filter_by(rings, query, & &1.name)
  def filter_ring_videos(videos, query), do: filter_by(videos, query, & &1.title)

  def grouped_ring_videos(videos, all_categories, query) do
    by_cat =
      videos
      |> filter_ring_videos(query)
      |> Enum.reject(&is_nil(&1.category))
      |> Enum.group_by(& &1.category.id)

    all_categories
    |> Enum.map(&%{id: &1.id, category: &1.name, videos: Map.get(by_cat, &1.id, [])})
    |> Enum.sort_by(&String.downcase(&1.category))
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
    normalized = text |> String.trim() |> String.replace(~r/\s+/, " ")

    if String.length(normalized) > max_length,
      do: String.slice(normalized, 0, max_length) <> "…",
      else: normalized
  end

  def short_annotation_preview(_text, _max_length), do: ""
end
