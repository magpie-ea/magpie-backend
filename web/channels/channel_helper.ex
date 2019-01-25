defmodule BABE.ChannelHelper do
  @moduledoc """
  Helper module for functionalities common to all channels.
  """
  alias BABE.{Repo, ExperimentStatus}
  require Ecto.Query

  @doc """
  Fetch experiment status with the given identifiers.
  """
  def get_experiment_status(experiment_id, variant, chain, realization) do
    status_query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.variant == ^variant,
        where: s.chain == ^chain,
        where: s.realization == ^realization
      )

    Repo.one!(status_query)
  end

  def get_all_available_assignments(experiment_id) do
    # This could be a bit slow but I hope it will still be efficient enough. The participant can wait.
    available_assignments_query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.status == 0,
        # First by realization, then by chain, then by variant. In this way the variant gets incremented first.
        order_by: [s.realization, s.chain, s.variant]
        # limit: 1
      )

    Repo.all(available_assignments_query)
  end
end
