defmodule BABE.Repo.Migrations.AddUniqueIndexToExperiment do
  use Ecto.Migration

  def change do
    create unique_index(:experiments, [:experiment_id, :author], name: :experiment_index)
  end
end
