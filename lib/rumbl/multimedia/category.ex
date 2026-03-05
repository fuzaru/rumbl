defmodule Rumbl.Multimedia.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Rings.Ring

  @foreign_key_type :binary_id
  schema "categories" do
    field :name, :string

    belongs_to :ring, Ring
    has_many :videos, Rumbl.Multimedia.Video

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :ring_id])
    |> validate_required([:name, :ring_id])
    |> assoc_constraint(:ring)
    |> unique_constraint(:name, name: :categories_ring_id_name_index)
  end
end
