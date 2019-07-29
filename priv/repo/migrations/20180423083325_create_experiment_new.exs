# This is the creation of the true "Experiment" table used to manage experiments now
defmodule Magpie.Repo.Migrations.CreateExperimentNew do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :experiment_id, :string
      add :author, :string
      add :description, :text
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:experiments, [:experiment_id])
    create index(:experiments, [:author])
  end
end
