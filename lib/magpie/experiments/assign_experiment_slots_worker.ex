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

  # It probably needs to keep track of the experiment_id it's responsible of...
  def start_link(experiment_id) do
    GenServer.start_link(__MODULE__, experiment_id,
      name: "assign_experiment_slots_worker_#{experiment_id}"
    )
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

    # We should probably just try to call get_and_set_to_in_progress_next_free_slot the number of times
    # that corresponds to the number of participants waiting in the queue?
    # Oh wait, don't we always have available slots?
    # I guess that's not actually true. It does depend on the strategy doesn't it.
    {:ok, participants} = WaitingQueueWorker.get_all_enqueued_participants()

    # Enum.each(participants, fn participant ->
    #   case Slots.get_and_set_to_in_progress_next_free_slot() do
    #     () ->
    #       nil
    #   end
    # end)
  end
end
