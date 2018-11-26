defmodule BABE.Repo.Migrations.SetOnDeleteForExperimentResults do
  use Ecto.Migration

  def up do
    # We still drop the constraint in `up` because the command below it will recreate the constraint.
    drop(constraint(:experiment_results, "experiment_results_experiment_id_fkey"))

    alter table(:experiment_results) do
      modify(:experiment_id, references(:experiments, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:experiment_results, "experiment_results_experiment_id_fkey"))

    alter table(:experiment_results) do
      modify(:experiment_id, references(:experiments, on_delete: :nothing))
    end
  end
end
