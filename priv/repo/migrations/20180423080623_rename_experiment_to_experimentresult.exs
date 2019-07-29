defmodule Magpie.Repo.Migrations.RenameExperimentToExperimentresult do
  use Ecto.Migration

  def change do
    drop index(:experiments, [:experiment_id])
    drop index(:experiments, [:author])
    rename table("experiments"), to: table("experiment_results")
    create index(:experiment_results, [:experiment_id])
    create index(:experiment_results, [:author])
  end
end
