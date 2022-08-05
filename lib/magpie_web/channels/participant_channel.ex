defmodule Magpie.ParticipantChannel do
  @moduledoc """
  Channel dedicated to keeping individual connections with each participant
  """

  use MagpieWeb, :channel

  alias Ecto.Multi
  alias Magpie.Experiments
  alias Magpie.Experiments.{AssignmentIdentifier, ExperimentStatus, ExperimentResult}
  alias Magpie.Presence
  alias Magpie.Repo

  alias Magpie.Experiments.WaitingQueueWorker

  require Ecto.Query
  require Logger

  @doc """
  The first step after establishing connection for any participant is to log in with a (randomly generated in the frontend) participant_id
  """
  def join("participant:" <> participant_id, _payload, socket) do
    # The participant_id should have been stored in the socket assigns already, and should match what the client tries to send us.
    if socket.assigns.participant_id == participant_id do
      :ok =
        Magpie.Experiments.ChannelWatcher.monitor(
          :participants,
          self(),
          {__MODULE__, :handle_leave, [socket, participant_id]}
        )

      send(self(), :after_participant_join)

      # Seems that we'll have to first return {:ok, socket} before we're able to broadcast anything to them? I'm not actually sure anymore lol. Let's still do it this way anyways.
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Reset the experiment status when the user leaves halfway through (e.g. closes the tab)

  An additional ChannelWatcher is also implemented according to https://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect so that handle_leave/1 is invoked also when the user loses connection, not just when they close the tab.
  """
  def handle_leave(socket, participant_id) do
    # If the user is still in the waiting queue, remove them from it.
    WaitingQueueWorker.dequeue_participant(participant_id)

    # We should probably reset the whole set of statuses, even if only one participant breaks out.
    # Note that we only deal with experiments with status 1, i.e. if any of other participants already saved the entire result and thus set the status to 2, the results would not be affected.
    Experiments.reset_in_progress_assignments_for_interactive_exp(
      socket.assigns.assignment_identifier
    )
  end

  def handle_info(:after_participant_join, socket) do
    case Slots.get_and_set_to_in_progress_next_free_slot(socket.assigns.experiment_id) do
      {:ok, slot_identifier} ->
        broadcast(socket, "slot_available", slot_identifier)

      :no_free_slot_available ->
        :ok = WaitingQueueWorker.queue_participant(socket.assigns.participant_id)

        broadcast(socket, "waiting_in_queue", %{})

      error ->
        broadcast(socket, "error_upon_joining", %{error: inspect(error)})
    end

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
        # I think now we can actually simply ask the next-in-line to join again.
        # So, we should actually broadcast in private to the ParticipantChannel of that user directly, instead of to the waiting room as a whole.
        # The waiting room is just a mechanism for us to get the id of the next participant.

        next_participant_id =
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

  #   defp assign_to_slot_or_to_waiting_queue(socket) do
  #     case Slots.get_and_set_to_in_progress_next_free_slot(socket.assigns.experiment_id) do
  #       {:ok, slot_identifier} ->
  #         broadcast(socket, "slot_available", slot_identifier)
  #         :ok

  #       :no_free_slot_available ->
  #         with :ok <- WaitingQueueWorker.queue_participant(socket.assigns.participant_id) do
  #           {:ok, :queued_up}
  #         end

  #         broadcast(socket, "waiting_in_queue", %{})

  #         :ok

  #       _ ->
  #         :error
  #     end
  #   end
end
