defmodule BABE.Repo.Migrations.AddDynamicRetrievalKeysToExperiment do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add :dynamic_retrieval_keys, {:array, :string}
    end
  end
end
