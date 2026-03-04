defmodule Rumbl.Rings.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Accounts.User
  alias Rumbl.Rings.Ring

  schema "ring_memberships" do
    field :role, :string, default: "member"

    belongs_to :ring, Ring, type: :binary_id
    belongs_to :user, User

    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :ring_id, :user_id])
    |> validate_required([:role, :ring_id, :user_id])
    |> validate_inclusion(:role, ["owner", "member"])
    |> unique_constraint(:ring_id, name: :ring_memberships_ring_id_user_id_index)
  end
end
