defmodule BABE.Repo.Migrations.RemoveOldInteractiveExperimentFieldsFromExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      remove(:is_interactive_experiment)
      remove(:num_participants_interactive_experiment)
    end
  end
end
