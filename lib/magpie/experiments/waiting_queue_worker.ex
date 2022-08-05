defmodule Magpie.Experiments.WaitingQueueWorker do
  @moduledoc """
    Worker to maintain a waiting queue for newly joined participants.
  """
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{queue: []}, name: __MODULE__)
  end

  ### API
  @doc """
  Add a participant to the queue by participant_id.
  """
  def queue_participant(participant_id) do
    GenServer.call(__MODULE__, {:queue_participant, participant_id})
  end

  @doc """
  Remove a participant from the queue, usually because they have disconnected.
  """
  def dequeue_participant(participant_id) do
    GenServer.cast(__MODULE__, {:dequeue_participant, participant_id})
  end

  @doc """
  Just return the participant at the front of the queue and removes them from the queue. Usually called when there is an available spot.
  """
  def pop_participant do
    GenServer.call(__MODULE__, :pop_participant)
  end

  ### Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:dequeue_participant, participant_id}, old_queue) do
    {:noreply, List.delete(old_queue, participant_id)}
  end

  @impl true
  def handle_call({:queue_participant, participant_id}, _from, old_queue) do
    {:reply, :ok, old_queue ++ [participant_id]}
  end

  # The queue is already empty.
  @impl true
  def handle_call(:pop_participant, _from, []) do
    {:reply, {:error, :queue_empty}, []}
  end

  # We still have somebody in the queue.
  @impl true
  def handle_call(:pop_participant, _from, [first_in_the_queue | tail]) do
    {:reply, {:ok, first_in_the_queue}, tail}
  end
end
