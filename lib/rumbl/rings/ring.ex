defmodule Rumbl.Rings.Ring do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Accounts.User
  alias Rumbl.Rings.{Membership, RingInvitation}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rings" do
    field :name, :string
    field :invite_code, :string

    belongs_to :owner, User, type: :id
    has_many :memberships, Membership
    has_many :invitations, RingInvitation

    timestamps()
  end

  def changeset(ring, attrs) do
    ring
    |> cast(attrs, [:name, :invite_code])
    |> validate_required([:name, :invite_code])
    |> validate_length(:name, min: 2, max: 60)
    |> unique_constraint(:invite_code)
  end
end
