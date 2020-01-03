defmodule Magpie.Repo.Migrations.AddResultTypeToExperimentResults do
  use Ecto.Migration

  def change do
    alter table(:experiment_results) do
      add(:is_intermediate, :boolean, default: false)
    end
  end
end
