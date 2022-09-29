defmodule Magpie.ParticipantChannel do
  @moduledoc """
  Channel dedicated to keeping individual connections with each participant
  """

  use MagpieWeb, :channel

  alias Magpie.Experiments
  alias Magpie.Experiments.Slots

  alias Magpie.Experiments.{
    AssignmentIdentifier,
    ChannelWatcher
  }

  alias Magpie.Experiments.WaitingQueueWorker

  require Ecto.Query
  require Logger

  ### API for calls from the outside
  # So this is the same as the GenServer mechanism.
  # I guess there's also no inherent reason why this function has to live in this module... It just simply makes more organizational sense to do so.
  def broadcast_next_slot_to_participant(participant_id, next_slot) do
    Magpie.Endpoint.broadcast("participant:#{participant_id}", "slot_available", next_slot)
  end

  @doc """
  The first step after establishing connection for any participant is to log in with a (randomly generated in the frontend) participant_id
  """
  def join("participant:" <> participant_id, _payload, socket) do
    # The participant_id should have been stored in the socket assigns already,
    # and should match what the client tries to send us.
    if socket.assigns.participant_id == participant_id do
      :ok =
        ChannelWatcher.monitor(
          :participants,
          self(),
          {__MODULE__, :handle_leave, [socket, participant_id]}
        )

      send(self(), :after_participant_join)

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
    WaitingQueueWorker.dequeue_participant(socket.assigns.experiment_id, participant_id)

    # TODO: Handle the case where the participant has already begun the experiment.
  end

  # Should the participant channel already try to find a slot? I'm not sure. There might also be the issue where some previously joined participants were still waiting, since the 5-sec interval for the AssignExperimentSlotsWorker has not been reached yet, while the newly joined participant gets the slot.
  # Let's always queue them to the back of the slot then.
  def handle_info(:after_participant_join, socket) do
    case WaitingQueueWorker.queue_participant(
           socket.assigns.experiment_id,
           socket.assigns.participant_id
         ) do
      :ok -> broadcast(socket, "waiting_in_queue", %{})
      error -> broadcast(socket, "error_upon_joining", %{error: inspect(error)})
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

  def handle_in("take_free_slot", slot_id, socket) do
    with {:ok, _experiment} <-
           Slots.set_slot_to_in_progress(socket.assigns.experiment_id, slot_id),
         :ok <-
           WaitingQueueWorker.dequeue_participant(
             socket.assigns.experiment_id,
             socket.assigns.participant_id
           ) do
      {:reply, :ok, socket}
    else
      error ->
        Logger.log(
          :error,
          "take_free_slot failed for participant #{socket.assigns.participant_identifier} with the errors: #{inspect(error)}"
        )

        {:reply, :error, socket}
    end
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
        ChannelWatcher.demonitor(:participants, self())

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
