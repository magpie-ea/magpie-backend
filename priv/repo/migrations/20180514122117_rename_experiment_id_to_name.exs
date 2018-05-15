defmodule BABE.Repo.Migrations.RenameExperimentIdToName do
  use Ecto.Migration

  def change do
      rename table(:experiments), :experiment_id, to: :name
  end
end
