defmodule Rumbl.Repo.Migrations.ScopeCategoriesToRings do
  use Ecto.Migration

  def up do
    alter table(:categories) do
      add :ring_id, references(:rings, type: :binary_id, on_delete: :delete_all)
    end

    create index(:categories, [:ring_id])
    drop_if_exists unique_index(:categories, [:name])

    execute("""
    INSERT INTO categories (name, ring_id, inserted_at, updated_at)
    SELECT DISTINCT c.name, v.ring_id::uuid, NOW(), NOW()
    FROM videos AS v
    JOIN categories AS c ON c.id = v.category_id
    WHERE v.category_id IS NOT NULL
      AND v.ring_id IS NOT NULL
      AND v.ring_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    """)

    execute("""
    UPDATE videos AS v
    SET category_id = c_new.id
    FROM categories AS c_old
    JOIN categories AS c_new
      ON c_new.name = c_old.name
    WHERE v.category_id = c_old.id
      AND c_new.ring_id = v.ring_id::uuid
      AND c_old.ring_id IS NULL
      AND v.ring_id IS NOT NULL
      AND v.category_id IS NOT NULL
      AND v.ring_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    """)

    execute("DELETE FROM categories WHERE ring_id IS NULL")

    alter table(:categories) do
      modify :ring_id, :binary_id, null: false
    end

    create unique_index(:categories, [:ring_id, :name])
  end

  def down do
    drop_if_exists unique_index(:categories, [:ring_id, :name])

    alter table(:categories) do
      modify :ring_id, :binary_id, null: true
    end

    execute("""
    DELETE FROM categories c1
    USING categories c2
    WHERE c1.id > c2.id
      AND c1.name = c2.name
    """)

    create unique_index(:categories, [:name])

    alter table(:categories) do
      remove :ring_id
    end
  end
end
