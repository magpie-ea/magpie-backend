defmodule Magpie.ChannelWatcher do
  @moduledoc """
  A module to watch out for participant disconnections. Phoenix.Presence and the terminate/2 callback might not be foolproof. See: https://github.com/magpie-project/Magpie/issues/51
  """
  use GenServer

  ## Client
  # MFA: module, function, argument. In this case it refers to the function that handles a participant leaving.
  def monitor(server_name, pid, mfa) do
    GenServer.call(server_name, {:monitor, pid, mfa})
  end

  def demonitor(server_name, pid) do
    GenServer.call(server_name, {:demonitor, pid})
  end

  ## Server
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    # In this way, the exit signals received from links will be converted into messages and put intside the mailbox.
    # All supervisors trap exits of their child processes
    Process.flag(:trap_exit, true)
    {:ok, %{participants: Map.new()}}
  end

  def handle_call({:monitor, pid, mfa}, _from, state) do
    Process.link(pid)
    {:reply, :ok, add_participant(state, pid, mfa)}
  end

  def handle_call({:demonitor, pid}, _from, state) do
    case Map.fetch(state.participants, pid) do
      # If the pid is not present anyways, we don't need to do anything
      :error ->
        {:reply, :ok, state}

      {:ok, _mfa} ->
        Process.unlink(pid)
        {:reply, :ok, drop_participant(state, pid)}
    end
  end

  # If we receive an exit signal from the participant channel, we run the callback.
  def handle_info({:EXIT, pid, reason}, state) do
    # This is ugly though I don't think there is any better solution currently
    # Whenever a test ends the following path happens
    # Whenever the following path doesn't match, a genuine exit in the production environment happened, so we can use the `else` clause for our real code.
    with :test <- Application.get_env(:magpie, :environment),
         :shutdown <- reason do
      {:noreply, drop_participant(state, pid)}
    else
      _ ->
        case Map.fetch(state.participants, pid) do
          :error ->
            {:noreply, state}

          {:ok, {mod, func, args}} ->
            Task.start_link(mod, func, args)
            {:noreply, drop_participant(state, pid)}
        end
    end
  end

  defp add_participant(state, pid, mfa) do
    %{state | participants: Map.put(state.participants, pid, mfa)}
  end

  defp drop_participant(state, pid) do
    %{state | participants: Map.delete(state.participants, pid)}
  end
end
