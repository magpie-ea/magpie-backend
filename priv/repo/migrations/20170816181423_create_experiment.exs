defmodule WoqWebapp.Repo.Migrations.CreateExperiment do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :results, :map
      # Not to be confused with the `id` used by the DB to index entries, thus the prefix.
      add :experiment_id, :string
      add :author, :string
      # Note that the migration type :text is actually used for Postgres. It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
      add :description, :text
      timestamps()
    end
  end
end
