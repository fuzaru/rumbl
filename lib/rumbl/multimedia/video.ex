defmodule Rumbl.Multimedia.Video do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Accounts.User
  alias Rumbl.Multimedia.{Category, Annotation}

  # Regexes compiled once at module load
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
    |> validate_change(:url, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: s, host: h} when s in ["http", "https"] and not is_nil(h) -> []
        _ -> [{:url, "must be a valid URL"}]
      end
    end)
    |> assoc_constraint(:user)
    |> assoc_constraint(:category)
    |> then(fn
      %{valid?: true, changes: %{title: title}} = cs ->
        slug =
          title
          |> String.downcase()
          |> String.replace(@slug_strip, "")
          |> String.replace(@slug_spaces, "-")
          |> String.trim("-")

        # Add random suffix for uniqueness
        put_change(cs, :slug, "#{slug}-#{:rand.uniform(9999)}")

      cs ->
        cs
    end)
    |> unique_constraint(:slug)
  end

  def youtube_id(%__MODULE__{url: url}) do
    case Regex.run(@youtube_re, url || "") do
      [_, id] -> id
      _ -> nil
    end
  end
end
