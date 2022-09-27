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
  Remove a participant from the queue, usually because they have disconnected.
  """
  def dequeue_participant(experiment_id, participant_id) do
    GenServer.cast(__MODULE__, {:dequeue_participant, {experiment_id, participant_id}})
  end

  @doc """
  Just return the participant at the front of the queue and removes them from the queue. Usually called when there is an available spot.
  """
  def pop_participant(experiment_id) do
    GenServer.call(__MODULE__, {:pop_participant, experiment_id})
  end

  # @doc """
  # Returns all the waiting participants in the queue.
  # """
  # def get_all_enqueued_participants do
  #   GenServer.call(__MODULE__, :get_all_enqueued_participants)
  # end

  @doc """
  Get all queues in a map, with experiment_id as keys and queue as values.
  """
  def get_all_queues do
    GenServer.call(__MODULE__, :get_all_queues)
  end

  # def poll_waiting_queue do

  # end

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

  # The queue is already empty.
  # @impl true
  # def handle_call(:pop_participant, _experiment_id, _from, []) do
  #   {:reply, {:error, :queue_empty}, []}
  # end

  # We still have somebody in the queue.
  # @impl true
  # def handle_call(:pop_participant, experiment_id, _from, [first_in_the_queue | tail]) do
  #   {:reply, {:ok, first_in_the_queue}, tail}
  # end

  @impl true
  def handle_call({:pop_participant, experiment_id}, _from, queues) do
    queue_for_experiment = Map.get(queues, experiment_id, [])

    case queue_for_experiment do
      [] ->
        {:reply, {:error, :queue_empty}, queues}

      [first_in_the_queue | tail] ->
        {:reply, {:ok, first_in_the_queue}, Map.put(queues, experiment_id, tail)}
    end
  end

  # @impl true
  # def handle_call(:get_all_enqueued_participants, _from, participants) do
  #   {:reply, {:ok, participants}, participants}
  # end

  @impl true
  def handle_call({:get_queue, experiment_id}, _from, queues) do
    {:reply, {:ok, Map.get(queues, experiment_id, [])}, queues}
  end

  @impl true
  def handle_call(:get_all_queues, _from, queues) do
    {:reply, {:ok, queues}, queues}
  end
end
