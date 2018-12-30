defmodule BABE.IteratedLobbyChannel do
  @moduledoc """
  Channel for participants who need to wait for other participants to finish first.
  """
  use BABE.Web, :channel
  alias BABE.ChannelHelper
  alias BABE.Presence
  alias BABE.{Repo, ExperimentStatus, ExperimentResult}
  alias Ecto.Multi

  @doc """
  A client can then decide which experiment results it wants to wait for. Once the experiment results are submitted, they will be informed.

  Though I'm not even sure if we actually need this callback or not if we're not going to do anything special with it. Let's see what happens then.
  """
  def join(
        "iterated_lobby:" <> assignment_trituple,
        _payload,
        socket
      ) do
    case String.split(assignment_trituple, ":") do
      [variant, chain, realization] ->
        send(self(), {:after_participant_join, variant, chain, realization})
        {:ok, socket}

      _ ->
        {:error, %{reason: "wrong_format"}}
    end
  end

  def handle_info({:after_participant_join, variant, chain, realization}, socket) do
    experiment_status =
      ChannelHelper.get_experiment_status(
        socket.assigns.experiment_id,
        variant,
        chain,
        realization
      )

    case experiment_status.status do
      2 ->
        results_query =
          from(r in ExperimentResult,
            where: r.experiment_id == ^socket.assigns.experiment_id,
            where: r.variant == ^variant,
            where: r.chain == ^chain,
            where: r.realization == ^realization
          )

        experiment_results = Repo.one!(results_query)

        # Just as what we do when the waited-on participant submits their results, send the results to all participants waiting for this participant.
        BABE.Endpoint.broadcast!(
          "iterated_lobby:#{variant}:#{chain}:#{realization}",
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
