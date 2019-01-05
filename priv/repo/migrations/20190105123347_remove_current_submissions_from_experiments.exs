defmodule BABE.Repo.Migrations.RemoveCurrentSubmissionsFromExperiments do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      remove(:current_submissions)
    end
  end
end
