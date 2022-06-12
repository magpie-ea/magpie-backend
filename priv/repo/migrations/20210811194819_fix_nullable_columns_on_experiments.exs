defmodule Magpie.Repo.Migrations.FixNullableColumnsOnExperiments do
  use Ecto.Migration

  import Ecto.Query
  alias Magpie.Experiments.{Experiment, ExperimentResult}
  alias Magpie.Repo

  def up do
    num_players_null_experiments_query =
      from(e in Experiment,
        where: is_nil(e.num_players)
      )

    Repo.update_all(num_players_null_experiments_query, set: [num_players: 1])

    num_chains_null_experiments_query =
      from(e in Experiment,
        where: is_nil(e.num_chains)
      )

    Repo.update_all(num_chains_null_experiments_query, set: [num_chains: 1])

    num_variants_null_experiments_query =
      from(e in Experiment,
        where: is_nil(e.num_variants)
      )

    Repo.update_all(num_variants_null_experiments_query, set: [num_variants: 1])

    num_generations_null_experiments_query =
      from(e in Experiment,
        where: is_nil(e.num_generations)
      )

    Repo.update_all(num_generations_null_experiments_query, set: [num_generations: 1])

    player_null_experiment_results_query =
      from(er in ExperimentResult,
        where: is_nil(er.player)
      )

    Repo.update_all(player_null_experiment_results_query, set: [player: 1])

    variant_null_experiment_results_query =
      from(er in ExperimentResult,
        where: is_nil(er.variant)
      )

    Repo.update_all(variant_null_experiment_results_query, set: [variant: 1])

    chain_null_experiment_results_query =
      from(er in ExperimentResult,
        where: is_nil(er.chain)
      )

    Repo.update_all(chain_null_experiment_results_query, set: [chain: 1])

    generation_null_experiment_results_query =
      from(er in ExperimentResult,
        where: is_nil(er.generation)
      )

    Repo.update_all(generation_null_experiment_results_query, set: [generation: 1])

    alter table(:experiments) do
      modify(:name, :string, null: false)
      modify(:author, :string, null: false)
      # Default all of them to 1
      modify(:num_variants, :integer, null: false, default: 1)
      modify(:num_chains, :integer, null: false, default: 1)
      modify(:num_generations, :integer, null: false, default: 1)
      modify(:is_dynamic, :boolean, null: false, default: false)
    end

    alter table(:experiment_results) do
      modify(:variant, :integer, null: false, default: 1)
      modify(:chain, :integer, null: false, default: 1)
      modify(:generation, :integer, null: false, default: 1)
      modify(:player, :integer, null: false, default: 1)
    end
  end

  def down do
    alter table(:experiments) do
      modify(:name, :string, null: true)
      modify(:author, :string, null: true)
      # Default all of them to 1
      modify(:num_variants, :integer, null: true)
      modify(:num_chains, :integer, null: true)
      modify(:num_generations, :integer, null: true)
      modify(:is_dynamic, :boolean, null: true, default: false)
    end

    alter table(:experiment_results) do
      modify(:variant, :integer, null: true, default: 1)
      modify(:chain, :integer, null: true, default: 1)
      modify(:generation, :integer, null: true, default: 1)
      modify(:player, :integer, null: true, default: 1)
    end
  end
end
