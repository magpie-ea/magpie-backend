defmodule Magpie.Repo.Migrations.MakeResultsInExperimentResultsNonNullable do
  use Ecto.Migration

  # Actually I'm not even sure if this will stop empty JSONs. Probably will need to perform a check at controller level anyways.
  def up do
    alter table(:experiment_results) do
      modify(:results, {:array, :map}, null: false)
    end
  end

  def down do
    alter table(:experiment_results) do
      modify(:results, {:array, :map})
    end
  end
end
