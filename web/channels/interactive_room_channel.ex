defmodule BABE.InteractiveRoomChannel do
  @moduledoc """
  Channel for maintaining lobbies in experiments which require multiple participants to interact with each other.

  The client should make use of the presence_diff event to decide if a game can be started.
  """

  use BABE.Web, :channel
  alias BABE.Presence

  @doc """
  Let the participant join the lobby and wait in there.

  One lobby is created for one
  """
  def join("interactive_room:" <> assignment_identifier, _payload, socket) do
    # Need to convert the values stored in socket.assigns to strings. Otherwise they cannot be compared to the topic string.
    if assignment_identifier ==
         "#{socket.assigns.experiment_id}:#{socket.assigns.chain}:#{socket.assigns.realization}" do
      send(self(), :after_participant_join)

      {:ok, socket}
    else
      {:error, %{reason: "wrong_format"}}
    end
  end

  def handle_info(:after_participant_join, socket) do
    # Add this participant to the list of all participants waiting in the lobby of this experiment.
    # Let me just make the following assumption: An interactive experiment must happen between participants of the same chain and realization.
    # If they need something more complicated in the future, change the structure by then.
    # This Presence can also be helpful in informing participants when one participant drops out.
    Presence.track(socket, "#{socket.assigns.participant_id}", %{
      variant: socket.assigns.variant,
      chain: socket.assigns.chain,
      realization: socket.assigns.realization,
      online_at: inspect(System.system_time(:second))
    })

    existing_participants = Map.keys(Presence.list(socket))

    # Start the experiment if the predefined number of variants is reached.
    # We could also send a presence_state event to the clients. Though this is the easy way to do it.
    if length(existing_participants) >= socket.assigns.num_variants do
      broadcast!(socket, "start_game", %{})
    end

    {:noreply, socket}
  end

  @doc """
  This handles new messages from the clients and broadcast them to everybody susbcribed to the same topic (i.e. who joined the same lounge).
  """
  def handle_in("new_msg", payload, socket) do
    broadcast(socket, "new_msg", payload)
    {:noreply, socket}
  end

  @doc """
  In many cases the game initialization needs to be handled by the client, since the server remains as generic as possible and just provides a channel for communication.

  The client can always use `new_msg` for everything, though specialized message types could help ease the job.
  """
  def handle_in("initialize_game", payload, socket) do
    broadcast(socket, "initialize_game", payload)
    {:noreply, socket}
  end

  @doc """
  Message indicating that the game is to be advanced to the next round.
  """
  def handle_in("next_round", payload, socket) do
    broadcast(socket, "next_round", payload)
    {:noreply, socket}
  end

  @doc """
  Message indicating that the game has ended.
  """
  def handle_in("end_game", payload, socket) do
    broadcast(socket, "end_game", payload)
    {:noreply, socket}
  end
end
