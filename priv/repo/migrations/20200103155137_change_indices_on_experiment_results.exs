defmodule Magpie.Repo.Migrations.ChangeIndicesOnExperimentResults do
  use Ecto.Migration

  def up do
    drop(
      index(:experiment_results, [:experiment_id, :variant, :chain, :realization], unique: true)
    )

    create(index(:experiment_results, [:experiment_id, :chain, :realization], unique: false))

    create(
      index(
        :experiment_results,
        [:experiment_id, :chain, :realization, :variant, :is_intermediate],
        unique: false
      )
    )
  end

  def down do
    drop(index(:experiment_results, [:experiment_id, :chain, :realization], unique: false))

    drop(
      index(
        :experiment_results,
        [:experiment_id, :chain, :realization, :variant, :is_intermediate],
        unique: false
      )
    )

    create(
      index(:experiment_results, [:experiment_id, :variant, :chain, :realization], unique: true)
    )
  end
end
