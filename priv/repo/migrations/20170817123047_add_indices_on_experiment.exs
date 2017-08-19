defmodule ProComPrag.Repo.Migrations.AddIndexOnExperimentId do
  use Ecto.Migration

  def change do
    # For now we'll use these two columns to query the experiments and return results.
    create index(:experiments, [:experiment_id])
    create index(:experiments, [:author])
  end
end
