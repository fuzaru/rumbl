defmodule Rumbl.Multimedia do
  import Ecto.Query, warn: false
  alias Rumbl.Repo
  alias Rumbl.Accounts.User
  alias Rumbl.Multimedia.{Video, Category, Annotation}

  # Videos

  def list_videos, do: Repo.all(Video) |> Repo.preload([:user, :category])

  def list_videos_for_ring(ring_id) when is_binary(ring_id) do
    from(v in Video, where: v.ring_id == ^ring_id, order_by: [desc: v.inserted_at])
    |> Repo.all()
    |> Repo.preload([:user, :category])
  end

  def list_user_videos(%User{} = user) do
    Video |> user_videos_query(user) |> Repo.all() |> Repo.preload([:category])
  end

  def search_videos_for_rings(ring_ids, query, opts \\ [])
      when is_list(ring_ids) and is_binary(query) do
    term = String.trim(query)

    if ring_ids == [] or term == "" do
      []
    else
      pattern = "%#{term}%"

      from(v in Video,
        where: v.ring_id in ^ring_ids and ilike(v.title, ^pattern),
        order_by: [desc: v.inserted_at],
        limit: ^Keyword.get(opts, :limit, 12)
      )
      |> Repo.all()
      |> Repo.preload([:user])
    end
  end

  def get_video!(slug) when is_binary(slug),
    do: Repo.one!(from v in Video, where: v.slug == ^slug, preload: [:user, :category])

  def get_user_video!(%User{} = user, slug) when is_binary(slug) do
    Video |> user_videos_query(user) |> where([v], v.slug == ^slug) |> Repo.one!()
  end

  def create_video(%User{} = user, attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def update_video(%Video{} = video, attrs),
    do: video |> Video.changeset(attrs) |> Repo.update()

  def delete_video(%Video{} = video), do: Repo.delete(video)

  def change_video(%Video{} = video, attrs \\ %{}), do: Video.changeset(video, attrs)

  defp user_videos_query(query, %User{id: user_id}),
    do: from(v in query, where: v.user_id == ^user_id)

  # ============================================================================
  # Categories
  # ============================================================================

  def list_categories_for_ring(ring_id) when is_binary(ring_id) do
    case Ecto.UUID.cast(ring_id) do
      {:ok, cast_id} ->
        Category
        |> where([c], c.ring_id == ^cast_id)
        |> order_by([c], c.name)
        |> Repo.all()

      :error ->
        []
    end
  end

  def list_categories_for_ring(_ring_id), do: []

  def category_options(ring_id) when is_binary(ring_id),
    do: ring_id |> list_categories_for_ring() |> Enum.map(&{&1.name, &1.id})

  def category_options(_ring_id), do: []

  def get_category_by_name(name, ring_id) when is_binary(name) and is_binary(ring_id),
    do: Repo.get_by(Category, name: name, ring_id: ring_id)

  def get_category!(id), do: Repo.get!(Category, id)

  def get_category_for_ring!(id, ring_id),
    do: Repo.get_by!(Category, id: id, ring_id: ring_id)

  def create_category(ring_id, attrs \\ %{}) when is_binary(ring_id),
    do: %Category{} |> Category.changeset(Map.put(attrs, "ring_id", ring_id)) |> Repo.insert()

  def delete_category(%Category{} = category), do: Repo.delete(category)

  # ============================================================================
  # Annotations
  # ============================================================================

  def list_annotations(%Video{} = video) do
    from(a in Annotation, where: a.video_id == ^video.id, order_by: [asc: a.at], preload: :user)
    |> Repo.all()
  end

  def annotate_video(%User{id: user_id}, video_id, attrs),
    do:
      %Annotation{user_id: user_id, video_id: video_id}
      |> Annotation.changeset(attrs)
      |> Repo.insert()

  def get_video_annotation(video_id, annotation_id)
      when is_integer(video_id) and is_integer(annotation_id),
      do:
        Repo.one(from a in Annotation, where: a.video_id == ^video_id and a.id == ^annotation_id)

  def delete_annotation(%Annotation{} = annotation), do: Repo.delete(annotation)
end
