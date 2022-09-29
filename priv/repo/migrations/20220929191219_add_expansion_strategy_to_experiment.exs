defmodule Magpie.Repo.Migrations.AddExpansionStrategyToExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add :expansion_strategy, :string, default: "expansive"
    end
  end
end
