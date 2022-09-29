defmodule Magpie.Experiments.AssignExperimentSlotsWorker do
  @moduledoc """
  Worker to periodically poll and assign available experiment slots to participants who are waiting for a slot.
  """
  use GenServer

  alias Magpie.Experiments.Slots
  alias Magpie.Experiments.WaitingQueueWorker

  @poll_waiting_queue_interval_ms if Application.compile_env(
                                       :magpie,
                                       :env
                                     ) == :test,
                                     do: 100,
                                     else: 10 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # We would poll the waiting queue every 10 seconds.
    Process.send_after(self(), :poll_waiting_queue, @poll_waiting_queue_interval_ms)

    {:ok, state}
  end

  @impl true
  def handle_info(:poll_waiting_queue, state) do
    # First do the scheduling.
    Process.send_after(self(), :poll_waiting_queue, @poll_waiting_queue_interval_ms)

    {:ok, queues} = WaitingQueueWorker.get_all_queues()

    Enum.each(queues, fn {experiment_id, queue} ->
      # OK, one further intricacy is that we will have to perform an expansion on the slots when there are no free slots available, if we set the expansion policy to be permissive.
      # Then another question comes: If the policy is permissive, should we create enough new slots until all the waiting candidates can be served?
      # I have a feeling that the way we think about "expansion" might be fundamentally flawed here. But it's hard to pinpoint this feeling. smh.
      # But, here's a but, maybe we can alleviate it by pre-creating enough slots as the very first step, so that this is already reasonably taken care of.
      # Then, we can indeed perform the expansion during the `free_slots` step, as we originally envisioned. Let's see then.
      ordered_free_slots = Slots.get_all_free_slots(experiment_id)

      # Match up the slots and the participants in the queue 1-to-1. Whichever is longer will get cut at the end.
      zipped = Enum.zip(ordered_free_slots, queue)

      Enum.each(zipped, fn {free_slot, participant_id} ->
        Magpie.ParticipantChannel.broadcast_next_slot_to_participant(
          free_slot,
          participant_id
        )
      end)
    end)

    {:noreply, state}
  end
end
