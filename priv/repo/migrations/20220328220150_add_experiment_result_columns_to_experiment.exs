defmodule Magpie.Repo.Migrations.AddExperimentResultColumnsToExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add :experiment_result_columns, {:array, :string}
    end
  end
end
