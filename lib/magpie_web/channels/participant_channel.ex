defmodule Magpie.ParticipantChannel do
  @moduledoc """
  Channel dedicated to keeping individual connections with each participant
  """

  use MagpieWeb, :channel
  alias Magpie.Experiments
  alias Magpie.Experiments.{AssignmentIdentifier, ExperimentStatus, ExperimentResult}
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
        Magpie.Experiments.ChannelWatcher.monitor(
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
    Experiments.reset_in_progress_assignments_for_interactive_exp(
      socket.assigns.assignment_identifier
    )
  end

  def handle_info(:after_participant_join, socket) do
    # Broadcast the tuple <variant-nr, chain-nr, generation-nr, player-nr> to the user.
    # We know that the experiment is available already when we accept the participant in ParticipantSocket.
    # However we can only broadcast the message after they've joined to the channel.
    broadcast(
      socket,
      "experiment_available",
      socket.assigns.assignment_identifier
    )

    # broadcast(socket, "experiment_available", %{
    #   variant: socket.assigns.assignment_status.variant,
    #   chain: socket.assigns.assignment_status.chain,
    #   generation: socket.assigns.assignment_status.generation,
    #   player: socket.assigns.assignment_status.player
    # })

    {:noreply, socket}
  end

  # A participant in a complex experiment needs to report their heartbeat every half a minute to keep occupying the slot.
  # This can be done via either the socket or via a normal REST call.
  # Here is the socket way.
  def handle_in("report_heartbeat", _payload, socket) do
    Experiments.report_heartbeat(socket.assigns.assignment_identifier)

    {:reply, :ok, socket}
  end

  # Record the submission when the client finishes the experiment. Set the experiment status to 2 (finished)
  # We might still allow the submissions via the REST API anyways. Both should be viable options.

  def handle_in("submit_results", payload, socket) do
    case Experiments.submit_experiment_results(
           socket.assigns.experiment_id,
           socket.assigns.assignment_identifier,
           payload["results"]
         ) do
      :ok ->
        Logger.log(
          :info,
          "Experiment results successfully saved for participant #{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)}"
        )

        # No need to monitor this participant anymore
        Magpie.Experiments.ChannelWatcher.demonitor(:participants, self())

        # Tell all clients that are waiting for results of this experiment that the experiment is finished, and send them the results.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)}",
          "finished",
          %{results: payload["results"]}
        )

        # Send a simple ack reply to the submitting client.
        {:reply, :ok, socket}

      {:error, error} ->
        Logger.log(
          :error,
          "Saving experiment results failed for participant #{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)} with the errors: #{inspect(error)}"
        )

        {:reply, :error, socket}
    end
  end

  # The client could send a "save_intermediate_progress" message even before the experiment finishes, so that experiment progress will not be lost if the client drops out before the end.
  # For now this is mainly useful when one participant drops out of an interactive experiment.
  def handle_in("save_intermediate_results", payload, socket) do
    intermediate_results = payload["results"]

    case Experiments.save_experiment_results(
           socket.assigns.experiment_id,
           socket.assigns.assignment_identifier,
           intermediate_results
         ) do
      {:ok, _} ->
        Logger.log(
          :info,
          "Experiment results successfully saved for participant #{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)}"
        )

        # Send a simple ack reply
        {:reply, :ok, socket}

      {:error, changeset} ->
        Logger.log(
          :error,
          "Saving experiment results failed for participant #{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)} with changeset
            #{inspect(changeset)}"
        )

        {:reply, :error, socket}
    end
  end
end
