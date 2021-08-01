defmodule Magpie.ChannelHelper do
  @moduledoc """
  Helper module for functionalities common to all channels.
  """
  alias Magpie.Experiments.ExperimentStatus
  alias Magpie.Repo
  require Ecto.Query

  @doc """
  Fetch experiment status with the given identifiers.
  """
  def get_experiment_status(experiment_id, variant, chain, generation) do
    status_query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.variant == ^variant,
        where: s.chain == ^chain,
        where: s.generation == ^generation
      )

    Repo.one!(status_query)
  end

  def get_all_available_assignments(experiment_id) do
    # This could be a bit slow but I hope it will still be efficient enough. The participant can wait.
    available_assignments_query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.status == 0,
        # First by variant, then by chain, then by generation. In this way the generation gets incremented first.
        order_by: [s.variant, s.chain, s.generation]
        # limit: 1
      )

    Repo.all(available_assignments_query)
  end
end
