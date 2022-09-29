defmodule Magpie.Experiments.WaitingQueueWorker do
  @moduledoc """
    Worker to maintain a waiting queue for newly joined participants.

    Oh well, do we actually need to spawn up a GenServer for each experiment? I think we do!
  """
  use GenServer

  # An alternative version we can use to have one worker per experiment.
  # def start_link(experiment_id) do
  #   GenServer.start_link(__MODULE__, %{queue: []}, name: "waiting_queue_worker_#{experiment_id}")
  # end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  ### API
  @doc """
  Add a participant to the queue by participant_id.

  It is a must to pass in the experiment id so that we know which queue the participant should go to.
  """
  def queue_participant(experiment_id, participant_id) do
    GenServer.call(__MODULE__, {:queue_participant, {experiment_id, participant_id}})
  end

  @doc """
  Remove a participant from the queue.
  Originally we also had a `pop_participant` function which removes and returns the participant at the same time. However, that might not be the best approach, as we may only want to remove the participant after we're sure the broadcasting of new slot went through. Therefore, the dequeue_participant function might actually be more useful.
  """
  def dequeue_participant(experiment_id, participant_id) do
    GenServer.cast(__MODULE__, {:dequeue_participant, {experiment_id, participant_id}})
  end

  @doc """
  Get all queues in a map, with experiment_id as keys and queue as values.
  """
  def get_all_queues do
    GenServer.call(__MODULE__, :get_all_queues)
  end

  ### Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:dequeue_participant, {experiment_id, participant_id}}, old_queues) do
    updated_queues =
      Map.update(old_queues, experiment_id, [], fn old_queue ->
        List.delete(old_queue, participant_id)
      end)

    {:noreply, updated_queues}
  end

  @impl true
  def handle_call({:queue_participant, {experiment_id, participant_id}}, _from, old_queues) do
    updated_queues =
      Map.update(old_queues, experiment_id, [participant_id], fn old_queue ->
        old_queue ++ [participant_id]
      end)

    {:reply, :ok, updated_queues}
  end

  # Unused
  # @impl true
  # def handle_call({:get_queue_for_experiment, experiment_id}, _from, queues) do
  #   {:reply, {:ok, Map.get(queues, experiment_id, [])}, queues}
  # end

  @impl true
  def handle_call(:get_all_queues, _from, queues) do
    {:reply, {:ok, queues}, queues}
  end
end
