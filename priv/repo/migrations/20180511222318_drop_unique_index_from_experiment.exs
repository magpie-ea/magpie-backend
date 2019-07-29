defmodule Magpie.Repo.Migrations.DropUniqueIndexFromExperiment do
  use Ecto.Migration

  def change do
    # This is no longer necessary as we actually want to allow the experiment_id and author to be the same, if the experimenter wants. The only unique identifier from now on will be the DB-generated ID.
    drop unique_index(:experiments, [:experiment_id, :author], name: :experiment_index)
  end
end
