defmodule Rumbl.Rings.RingInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rumbl.Accounts.User
  alias Rumbl.Rings.Ring

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ring_invitations" do
    field :status, :string, default: "pending"

    belongs_to :ring, Ring, type: :binary_id
    belongs_to :inviter, User, foreign_key: :inviter_id, type: :id
    belongs_to :invitee, User, foreign_key: :invitee_id, type: :id

    timestamps()
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:status, :ring_id, :inviter_id, :invitee_id])
    |> validate_required([:status, :ring_id, :inviter_id, :invitee_id])
    |> validate_inclusion(:status, ["pending", "accepted", "declined"])
    |> unique_constraint(:status, name: :ring_invitations_ring_id_invitee_id_status_index)
  end
end
