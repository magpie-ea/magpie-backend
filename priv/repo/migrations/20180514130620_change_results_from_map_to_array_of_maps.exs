defmodule ProComPrag.Repo.Migrations.ChangeResultsFromMapToArrayOfMaps do
  use Ecto.Migration

  def change do
    alter table(:experiment_results) do
      remove :results
      add :results, {:array, :map}
    end
  end
end
