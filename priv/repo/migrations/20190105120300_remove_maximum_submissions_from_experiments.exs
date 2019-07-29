defmodule Magpie.Repo.Migrations.RemoveMaximumSubmissionsFromExperiments do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      remove(:maximum_submissions)
    end
  end
end
