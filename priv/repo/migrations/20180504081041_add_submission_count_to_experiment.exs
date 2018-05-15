defmodule BABE.Repo.Migrations.AddSubmissionCountToExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add :maximum_submissions, :integer
      add :current_submissions, :integer, default: 0, null: false
    end
  end
end
