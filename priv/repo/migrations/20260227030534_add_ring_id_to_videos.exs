defmodule Rumbl.Repo.Migrations.AddRingIdToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :ring_id, :string
    end

    create index(:videos, [:ring_id])
  end
end
