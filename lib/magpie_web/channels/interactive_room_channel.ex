defmodule Magpie.InteractiveRoomChannel do
  @moduledoc """
  Channel for maintaining lobbies in interactive experiments which require multiple participants to with each other.

  The client should make use of the presence_diff event to decide if a game can be started.
  """

  use MagpieWeb, :channel
  alias Magpie.Experiments.AssignmentIdentifier
  alias Magpie.Presence

  @doc """
  Let the participant join the lobby and wait in there.

  One lobby is created for one combination of experiment_id:chain:variant:generation combination
  """
  # I'm a bit confused here though: Apparently the "socket" is the real socket. Then what happened to the channel process itself?
  def join("interactive_room:" <> room_identifier, _payload, socket) do
    if room_identifier ==
         AssignmentIdentifier.to_string(socket.assigns.assignment_identifier, false) do
      send(self(), :after_participant_join)

      {:ok, socket}
    else
      {:error, %{reason: "invalid_format"}}
    end
  end

  def handle_info(:after_participant_join, socket) do
    # Add this participant to the list of all participants waiting in the lobby of this experiment.
    # Let me just make the following assumption: An interactive experiment must happen between participants of the same chain, variant and generation.
    # If they need something more complicated in the future, change the structure by then.
    # This Presence can also be helpful in informing participants when one participant drops out.

    # Oh OK, I think I now understood how it works. With some magic under the hood, even though we're passing in "socket" as the first argument here, it automagically figures out that we're actually tracking this *channel*, which is of course room  `experiment_id:chain:variant:generation`.
    # There is another function Presence.track/4 which allows you to track any process by topic and key: track(pid, topic, key, meta)
    # But still it seems to me that the grouping key should be the assignment_identifier instead of the particular participant_id? I'm a bit confused at how this worked. Let's see.
    topic = AssignmentIdentifier.to_string(socket.assigns.assignment_identifier, false)

    Presence.track(
      socket,
      "#{topic}",
      %{
        participant_id: socket.assigns.participant_id,
        # This came from the official example.
        online_at: inspect(System.system_time(:second))
      }
    )

    # Note that the presence information will be returned as a map with presences *grouped by key*, together with the metadata.
    # Example:
    # %{
    #   "1:1:1:1" => %{
    #     metas: [
    #       %{
    #         online_at: "1629644124",
    #         participant_id: "b31e54b0e558d3a87fd3cd9530d07e297fe00d86",
    #         phx_ref: "Fp2osoV59TjSYAFE"
    #       },
    #       %{
    #         online_at: "1629644128",
    #         participant_id: "54080b46f09162477e36e05e22ad4f8aa9dda49f",
    #         phx_ref: "Fp2os3i8kgDSYAHE"
    #       }
    #     ]
    #   }
    # }
    # To get the participants, we first go by the topic name, then go under :meta
    existing_participants =
      socket
      |> Presence.list()
      |> Map.get(topic)
      |> Map.get(:metas)

    # Start the experiment if the predefined number of players is reached.
    # We could also send a presence_state event to the clients. Though this is the easy way to do it.
    if length(existing_participants) >= socket.assigns.num_players do
      group_label = :crypto.strong_rand_bytes(20)
      broadcast!(socket, "start_game", %{"group_label" => group_label})
    end

    {:noreply, socket}
  end

  # This handles new messages from the clients and broadcast them to everybody susbcribed to the same topic (i.e. who joined the same lounge).
  def handle_in("new_msg", payload, socket) do
    broadcast(socket, "new_msg", payload)
    {:noreply, socket}
  end

  # In many cases the game initialization needs to be handled by the client, since the server remains as generic as possible and just provides a channel for communication.
  # The client can always use `new_msg` for everything, though specialized message types could help ease the job.
  def handle_in("initialize_game", payload, socket) do
    broadcast(socket, "initialize_game", payload)
    {:noreply, socket}
  end

  # Message indicating that the game is to be advanced to the next round.
  def handle_in("next_round", payload, socket) do
    broadcast(socket, "next_round", payload)
    {:noreply, socket}
  end

  # Message indicating that the game has ended.
  def handle_in("end_game", payload, socket) do
    broadcast(socket, "end_game", payload)
    {:noreply, socket}
  end
end
