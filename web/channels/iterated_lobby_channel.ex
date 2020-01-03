defmodule Magpie.IteratedLobbyChannel do
  @moduledoc """
  Channel for maintaining lobbies for iterated experiments where new participants need to wait for previous participants to finish first.
  """
  use Magpie.Web, :channel
  alias Magpie.ChannelHelper
  alias Magpie.{Repo, ExperimentResult}

  @doc """
  A client can then decide which experiment results it wants to wait for. Once the experiment results are submitted, they will be informed.
  """
  def join(
        "iterated_lobby:" <> assignment_identifier,
        _payload,
        socket
      ) do
    case String.split(assignment_identifier, ":") do
      [experiment_id, variant, chain, realization] ->
        # By including `experiment_id` in the identifier we also allow a new participant to wait on the results of a previous experiment. Why not if they want to do so.
        send(self(), {:after_participant_join, experiment_id, variant, chain, realization})
        {:ok, socket}

      _ ->
        {:error, %{reason: "wrong_format"}}
    end
  end

  def handle_info({:after_participant_join, experiment_id, variant, chain, realization}, socket) do
    experiment_status =
      ChannelHelper.get_experiment_status(
        experiment_id,
        variant,
        chain,
        realization
      )

    case experiment_status.status do
      2 ->
        results_query =
          from(r in ExperimentResult,
            where: r.experiment_id == ^experiment_id,
            where: r.variant == ^variant,
            where: r.chain == ^chain,
            where: r.realization == ^realization,
            where: r.is_intermediate == false
          )

        experiment_results = Repo.one!(results_query)

        # The same as what we do when the waited-on participant submits their results, send the results to all participants waiting for this participant.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{experiment_id}:#{variant}:#{chain}:#{realization}",
          "finished",
          %{results: experiment_results.results}
        )

        {:noreply, socket}

      # I'm not sure if there's a valid case of waiting on an experiment whose status is 0. But I guess I should handle reassignments of dropouts elsewhere.
      _ ->
        {:noreply, socket}
    end
  end
end
