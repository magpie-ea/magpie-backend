defmodule BABE.ChannelHelper do
  use BABE.Web, :channel
  alias BABE.{Repo, ExperimentStatus, ExperimentResult}

  def get_experiment_status(experiment_id, variant, chain, realization) do
    status_query =
      from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.variant == ^variant,
        where: s.chain == ^chain,
        where: s.realization == ^realization
      )

    Repo.one!(status_query)
  end
end
