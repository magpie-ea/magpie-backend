defmodule Magpie.Repo.Migrations.AddForeignKeyToExperimentResult do
  use Ecto.Migration

  def change do
    drop index(:experiment_results, [:experiment_id])
    drop index(:experiment_results, [:author])

    alter table(:experiment_results) do
      remove :experiment_id
      remove :author
      remove :description

      # Now this "experiment_id" actually refers to the "experiments" table.
      add :experiment_id, references("experiments")
    end

    # index on the true experiment_id
    create index(:experiment_results, [:experiment_id])
  end
end
