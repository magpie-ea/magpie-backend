defmodule MagpieWeb.ExperimentChannel do
  @moduledoc """
  Channel for experiments.

  Essentially, we'd want the frontend to subscribe to the appropriate topics. But using one channel for all the topics seems to suffice. This would also be quite generalizable.
  """
  use MagpieWeb, :channel
  alias Magpie.Experiments.AssignmentIdentifier
  alias Magpie.Experiments
  alias Magpie.Experiments.Slots
  # alias Magpie.Presence
  require Logger

  # Topics for each participant separately.
  # Trying to use Presence directly and see how it goes here.
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

  # Topics for each experiment. Can be useful for maintaining the queue of participants waiting to be assigned the next free slot.
  # Always try to get and return the next available experiment upon joining?
  def join("waiting_queue:" <> experiment_id, _payload, socket) do
  end

  # Topics for each interactive experiment. The room_id is the AssignmentIdentifier, without the `_player_num` suffix.
  def join("interactive_room:" <> room_id, _payload, socket) do
  end

  def handle_info(:after_participant_join, socket) do
    # Presence.track(socket, )
    case Slots.get_and_set_to_in_progress_next_free_slot(socket.assigns.experiment_id) do
      {:ok, slot_identifier} ->
        broadcast(socket, "slot_available", slot_identifier)

      :no_free_slot_available ->
        # Let's first try to not use Presence, and simply broadcast to everybody listening for new experiments.
        # Presence.track(socket, "waiting_queue:#{socket.assigns.experiment_id}", %{
        #   participant_id: socket.assigns.participant_id,
        #   online_at: inspect(System.system_time(:second))
        # })

        broadcast(socket, "no_free_slot_available", %{})

      _ ->
        :error
    end
  end

  @doc """
  Reset the experiment status when the user leaves halfway through (e.g. closes the tab)

  N.B.: This callback might not catch situations where the connection times out etc. A GenServer as mentioned in https://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect could be useful.
  """
  def handle_leave(socket) do
  end

  def handle_in("request_free_slot", _payload, socket) do
    case Slots.get_and_set_to_in_progress_next_free_slot(socket.assigns.experiment_id) do
      {:ok, slot_identifier} ->
        broadcast(socket, "slot_available", slot_identifier)

      :no_free_slot_available ->
        # Let's first try to not use Presence, and simply broadcast to everybody listening for new experiments.
        # Presence.track(socket, "waiting_queue:#{socket.assigns.experiment_id}", %{
        #   participant_id: socket.assigns.participant_id,
        #   online_at: inspect(System.system_time(:second))
        # })

        broadcast(socket, "no_free_slot_available", %{})

      _ ->
        :error
    end
  end

  # A participant in a complex experiment needs to report their heartbeat every half a minute to keep occupying the slot.
  # This can be done via either the socket or via a normal REST call.
  # Here is the socket way.
  def handle_in("report_heartbeat", _payload, socket) do
    Experiments.report_heartbeat(socket.assigns.assignment_identifier)

    {:reply, :ok, socket}
  end

  # Record the submission when the client finishes the experiment.

  def handle_in("submit_results", payload, socket) do
    case Experiments.submit_experiment_results(
           socket.assigns.experiment_id,
           socket.assigns.assignment_identifier,
           payload["results"]
         ) do
      {:ok, freed_count} ->
        Logger.log(
          :info,
          "Experiment results successfully saved for participant #{AssignmentIdentifier.to_string(socket.assigns.assignment_identifier)}. #{freed_count} slots freed."
        )

        # No need to monitor this participant anymore
        Magpie.Experiments.ChannelWatcher.demonitor(:participants, self())

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

  # The client can send a "save_intermediate_progress" message even before the experiment finishes, so that experiment progress will not be totally lost if the client drops out before the end.
  # For now this is mainly useful when one participant drops out of an interactive experiment.
  def handle_in("save_intermediate_results", payload, socket) do
  end
end
