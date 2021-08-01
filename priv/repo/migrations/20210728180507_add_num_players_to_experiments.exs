defmodule Magpie.Repo.Migrations.AddNumPlayersToExperiments do
  use Ecto.Migration

  def up do
    alter table(:experiments) do
      add :num_players, :integer, default: 1, null: false
      add :is_interactive, :boolean, default: false, null: false
    end

    alter table(:experiment_results) do
      add :player, :integer, null: true
    end

    alter table(:experiment_statuses) do
      add :player, :integer, null: false
    end

    # Create additional indices without dropping the previous ones.
    create(
      index(
        :experiment_results,
        [:experiment_id, :generation, :variant, :chain, :player, :is_intermediate],
        unique: false
      )
    )

    create(
      index(:experiment_statuses, [:experiment_id, :generation, :variant, :chain, :player], unique: true)
    )

    # Maybe we'll run a query bypassing all the other fields.
    create(index(:experiment_results, [:experiment_id, :player], unique: false))

    create(index(:experiment_statuses, [:experiment_id, :player], unique: false))
  end

  def down do
    alter table(:experiments) do
      remove :num_players, :integer, null: true
      remove :is_interactive, :boolean, default: false, null: false
    end

    alter table(:experiment_results) do
      remove :player, :integer, null: true
    end

    alter table(:experiment_statuses) do
      remove :player, :integer, null: false
    end
  end
end
