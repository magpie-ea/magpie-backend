defmodule Magpie.Repo.Migrations.AddNumPlayersToExperiments do
  use Ecto.Migration

  def up do
    drop(
      index(:experiment_statuses, [:experiment_id, :generation, :variant, :chain])
    )

    drop(
      index(
        :experiment_results,
        [:experiment_id, :generation, :variant, :chain, :is_intermediate]
      )
    )

    alter table(:experiments) do
      add :num_players, :integer, default: 1, null: false
      add :is_interactive, :boolean, default: false, null: false
    end

    alter table(:experiment_results) do
      add :player, :integer, null: true
    end

    alter table(:experiment_statuses) do
      # Need to provide a default for all the previously existing entries.
      add :player, :integer, default: 1, null: false
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
    drop(
      index(
        :experiment_results,
        [:experiment_id, :generation, :variant, :chain, :player, :is_intermediate]
      )
    )

    drop(
      index(:experiment_statuses, [:experiment_id, :generation, :variant, :chain, :player])
    )

    # Maybe we'll run a query bypassing all the other fields.
    drop(index(:experiment_results, [:experiment_id, :player]))

    drop(index(:experiment_statuses, [:experiment_id, :player]))


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

    create(
      index(
        :experiment_results,
        [:experiment_id, :generation, :variant, :chain, :is_intermediate],
        unique: false
      )
    )

    create(
      index(:experiment_statuses, [:experiment_id, :generation, :variant, :chain], unique: true)
    )
  end
end
