defmodule Rumbl.Multimedia.Video do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Accounts.User
  alias Rumbl.Multimedia.{Category, Annotation}

  @slug_strip ~r/[^\w\s-]/
  @slug_spaces ~r/\s+/
  @youtube_re ~r{(?:youtube\.com/watch\?v=|youtu\.be/)([^&#?\s]+)}

  @derive {Phoenix.Param, key: :slug}

  schema "videos" do
    field :title, :string
    field :url, :string
    field :description, :string
    field :slug, :string
    field :ring_id, :string

    belongs_to :user, User
    belongs_to :category, Category
    has_many :annotations, Annotation

    timestamps()
  end

  def changeset(video, attrs) do
    video
    |> cast(attrs, [:title, :url, :description, :category_id, :ring_id])
    |> validate_required([:title, :url, :ring_id])
    |> validate_change(:url, &validate_url/2)
    |> assoc_constraint(:user)
    |> assoc_constraint(:category)
    |> put_slug()
    |> unique_constraint(:slug)
  end

  def youtube_id(%__MODULE__{url: url}) do
    case Regex.run(@youtube_re, url || "") do
      [_, id] -> id
      _ -> nil
    end
  end

  defp validate_url(_, url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) -> []
      _ -> [url: "must be a valid URL"]
    end
  end

  defp put_slug(%Ecto.Changeset{valid?: true, changes: %{title: title}} = changeset) do
    slug =
      title
      |> slugify_title()
      |> add_random_suffix()
      |> put_change(changeset, :slug, slug)
  end

  defp put_slug(changeset), do: changeset

  defp slugify_title(title) do
    title
    |> String.downcase()
    |> String.replace(@slug_strip, "")
    |> String.replace(@slug_spaces, "-")
    |> String.trim("-")
  end

  defp add_random_suffix(slug), do: "#{slug}-#{:rand.uniform(9999)}"
end
