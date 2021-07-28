defmodule Magpie.Repo.Migrations.RenameRealizationToGeneration do
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

    drop(
      index(:experiment_statuses, [:experiment_id, :variant, :chain, :realization], unique: true)
    )

    rename table(:experiments), :num_realizations, to: :num_generations

    rename table(:experiment_results), :realization, to: :generation

    rename table(:experiment_statuses), :realization, to: :generation

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

  def down do
    drop(
      index(
        :experiment_results,
        [:experiment_id, :generation, :variant, :chain, :is_intermediate],
        unique: false
      )
    )

    drop(
      index(:experiment_statuses, [:experiment_id, :generation, :variant, :chain], unique: true)
    )

    rename table(:experiments), :num_generations, to: :num_realizations

    rename table(:experiment_results), :generation, to: :realization

    rename table(:experiment_statuses), :generation, to: :realization

    alter table(:experiments) do
      remove(:num_generations)
      add(:num_realizations, :integer, null: true)
    end

    alter table(:experiment_results) do
      remove(:generation)
      add(:realization, :integer, null: true)
    end

    alter table(:experiment_statuses) do
      remove(:generation)
      add(:realization, :integer, null: false)
    end

    create(index(:experiment_results, [:experiment_id, :chain, :realization], unique: false))

    create(
      index(
        :experiment_results,
        [:experiment_id, :chain, :realization, :variant, :is_intermediate],
        unique: false
      )
    )

    create(
      index(:experiment_statuses, [:experiment_id, :variant, :chain, :realization], unique: true)
    )
  end
end
