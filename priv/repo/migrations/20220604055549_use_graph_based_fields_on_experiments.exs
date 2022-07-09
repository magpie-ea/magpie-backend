defmodule Magpie.Repo.Migrations.UseGraphBasedFieldsOnExperiments do
  use Ecto.Migration

  def up do
    drop(index(:experiment_results, [:experiment_id, :chain, :realization], unique: false))

    drop(
      index(
        :experiment_results,
        [:experiment_id, :chain, :realization, :variant, :is_intermediate],
        unique: false
      )
    )

    alter table(:experiments) do
      remove :is_dynamic
      remove :is_interactive

      add :is_ulc, :boolean, default: true
      add :copy_number, :integer, default: 0
      add :slot_ordering, {:array, :string}
      add :slot_statuses, :map
      add :slot_dependencies, :map
      add :slot_attempt_counts, :map
      add :trial_players, :map
      add :results, :map
    end

    # Feels like I don't even have a reason to use this dedicated table anymore.
    # But maybe it's still better. Let's see.
    alter table(:experiment_results) do
      remove :variant
      remove :chain
      remove :generation
      remove :player

      # Now we simply use one uniform identifier to fetch experiment results, since this can be flexibly specified by the experiment designer.
      add :identifier, :string
    end

    create(
      index(
        :experiment_results,
        :identifier,
        # Could be multiple people submitting the same result for whatever reason.
        unique: false
      )
    )
  end

  def down do
    drop(
      index(
        :experiment_results,
        :identifier,
        unique: false
      )
    )

    alter table(:experiments) do
      remove :is_ulc
      remove :copy_number
      remove :slot_ordering
      remove :slot_statuses
      remove :slot_dependencies
      remove :slot_attempt_counts
      remove :trial_players
      remove :results

      add :is_dynamic, :boolean, null: true, default: false
      add :is_interactive, :boolean, default: false, null: false
    end

    alter table(:experiment_results) do
      add :variant, :integer, null: false, default: 1
      add :chain, :integer, null: false, default: 1
      add :generation, null: false, default: 1
      add :player, null: false, default: 1

      remove :identifier
    end

    create(index(:experiment_results, [:experiment_id, :chain, :realization], unique: false))

    create(
      index(
        :experiment_results,
        [:experiment_id, :chain, :realization, :variant, :is_intermediate],
        unique: false
      )
    )
  end
end
