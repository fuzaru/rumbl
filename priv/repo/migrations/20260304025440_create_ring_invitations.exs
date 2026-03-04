defmodule Rumbl.Repo.Migrations.CreateRingInvitations do
  use Ecto.Migration

  def change do
    create table(:ring_invitations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false, default: "pending"
      add :ring_id, references(:rings, type: :binary_id, on_delete: :delete_all), null: false
      add :inviter_id, references(:users, on_delete: :delete_all), null: false
      add :invitee_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ring_invitations, [:ring_id])
    create index(:ring_invitations, [:inviter_id])
    create index(:ring_invitations, [:invitee_id])
    create unique_index(:ring_invitations, [:ring_id, :invitee_id, :status])
  end
end
