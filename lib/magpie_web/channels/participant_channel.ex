defmodule Magpie.ParticipantChannel do
  @moduledoc """
  Channel dedicated to keeping individual connections with each participant
  """

  use MagpieWeb, :channel
  alias Magpie.Experiments.{ExperimentStatus, ExperimentResult}
  alias Magpie.Repo
  alias Ecto.Multi
  require Ecto.Query
  require Logger

  @doc """
  The first step after establishing connection for any participant is to log in with a (in most cases randomly generated in the frontend) participant_id
  """
  def join("participant:" <> participant_id, _payload, socket) do
    # The participant_id should have been stored in the socket assigns already, and should match what the client tries to send us.
    if socket.assigns.participant_id == participant_id do
      send(self(), :after_participant_join)

      :ok =
        Magpie.ChannelWatcher.monitor(
          :participants,
          self(),
          {__MODULE__, :handle_leave, [socket]}
        )

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Reset the experiment status when the user leaves halfway through (e.g. closes the tab)

  N.B.: This callback might not catch situations where the connection times out, etc. A GenServer as mentioned in https://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect could be useful.
  """
  def handle_leave(socket) do
    # We should probably reset the whole set of statuses, even if only one participant breaks out.
    # Note that we only deal with experiments with status 1, i.e. if any of other participants already saved the entire result and thus set the status to 2, the results would not be affected.
    relevant_in_progress_experiment_statuses =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^socket.assigns.experiment_id,
        where: s.chain == ^socket.assigns.chain,
        where: s.realization == ^socket.assigns.realization,
        where: s.status == 1
      )

    Repo.update_all(relevant_in_progress_experiment_statuses, set: [status: 0])
  end

  def handle_info(:after_participant_join, socket) do
    # Broadcast the trituple <variant-nr, chain-nr, realization-nr> to the user.
    broadcast(socket, "experiment_available", %{
      variant: socket.assigns.variant,
      chain: socket.assigns.chain,
      realization: socket.assigns.realization
    })

    {:noreply, socket}
  end

  @doc """
  Record the submission when the client finishes the experiment. Set the experiment status to 2 (finished)

  We might still allow the submissions via the REST API anyways. Both should be viable options.
  """
  def handle_in("submit_results", payload, socket) do
    experiment_id = socket.assigns.experiment_id
    variant = socket.assigns.variant
    chain = socket.assigns.chain
    realization = socket.assigns.realization
    results = payload["results"]

    # When one participant finishes, set all relevant experiment statuses to "complete".
    relevant_experiment_statuses =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^socket.assigns.experiment_id,
        where: s.chain == ^socket.assigns.chain,
        where: s.realization == ^socket.assigns.realization
      )

    experiment_result_changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        %{
          experiment_id: experiment_id,
          results: results,
          variant: variant,
          chain: chain,
          realization: realization,
          is_intermediate: false
        }
      )

    operation =
      Multi.new()
      |> Multi.update_all(:experiment_statuses, relevant_experiment_statuses, set: [status: 2])
      |> Multi.insert(:experiment_result, experiment_result_changeset)

    case Repo.transaction(operation) do
      {:ok, _} ->
        Logger.log(
          :info,
          "Experiment results successfully saved for participant with chain #{chain}, realization #{realization}, variant #{variant}"
        )

        # No need to monitor this participant anymore
        Magpie.ChannelWatcher.demonitor(:participants, self())

        # Tell all clients that are waiting for results of this experiment that the experiment is finished, and send them the results.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{experiment_id}:#{variant}:#{chain}:#{realization}",
          "finished",
          %{results: results}
        )

        # Send a simple ack reply to the submitting client.
        {:reply, :ok, socket}

      {:error, failed_operation, failed_value, changes_so_far} ->
        Logger.log(
          :error,
          "Saving experiment results failed for participant with chain #{chain}, realization #{realization}, variant #{variant}, operation
          #{inspect(failed_operation)} failed with #{inspect(failed_value)}. Changes: #{inspect(changes_so_far)}"
        )

        {:reply, :error, socket}
    end
  end

  @doc """
  The client could send a "save_intermediate_progress" message even before the experiment finishes, so that experiment progress will not be lost if the client drops out before the end.

  For now this is mainly useful when one participant drops out of an interactive experiment.
  """
  def handle_in("save_intermediate_results", payload, socket) do
    experiment_id = socket.assigns.experiment_id
    variant = socket.assigns.variant
    chain = socket.assigns.chain
    realization = socket.assigns.realization
    intermediate_results = payload["results"]

    experiment_result_changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        %{
          experiment_id: experiment_id,
          results: intermediate_results,
          variant: variant,
          chain: chain,
          realization: realization,
          is_intermediate: true
        }
      )

    case Repo.insert(experiment_result_changeset) do
      {:ok, _} ->
        Logger.log(
          :info,
          "Experiment results successfully saved for participant with chain #{chain}, realization #{realization}, variant #{variant}"
        )

        # Send a simple ack reply
        {:reply, :ok, socket}

      {:error, changeset} ->
        Logger.log(
          :error,
          "Saving experiment results failed for participant with chain #{chain}, realization #{realization}, variant #{variant} with changeset
            #{inspect(changeset)}"
        )

        {:reply, :error, socket}
    end
  end
end
