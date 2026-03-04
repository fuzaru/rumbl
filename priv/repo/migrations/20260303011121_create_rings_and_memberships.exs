defmodule Rumbl.Repo.Migrations.CreateRingsAndMemberships do
  use Ecto.Migration

  def change do
    create table(:rings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :invite_code, :string, null: false
      add :owner_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rings, [:invite_code])
    create index(:rings, [:owner_id])

    create table(:ring_memberships) do
      add :role, :string, null: false, default: "member"
      add :ring_id, references(:rings, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:ring_memberships, [:ring_id, :user_id])
    create index(:ring_memberships, [:user_id])
  end
end
