defmodule Magpie.Repo.Migrations.AddInteractiveExperimentAttributesToExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add(:is_interactive_experiment, :boolean, default: false)
      add(:num_participants_interactive_experiment, :integer, null: true)
    end
  end
end
