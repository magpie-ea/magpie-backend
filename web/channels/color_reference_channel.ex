defmodule BABE.ColorReferenceChannel do
  use BABE.Web, :channel
  alias BABE.Presence

  @num_users_per_game 2

  @doc """
  The first step after establishing connection for any participant is to log in with a (in most cases randomly generated in the frontend) user_id
  """
  def join("color_reference:user:" <> user_id, _payload, socket) do
    if socket.assigns.user_id == user_id do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  After a participant successfully logs in, they should join the lobby.
  """
  def join("color_reference:lobby", _payload, socket) do
    Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })

    send(self(), :after_user_join_lobby)
    {:ok, socket}
  end

  @doc """
  After a user joins the lobby, check the target condition (in this experiment the condition is num_waiting_participants==2). If the condition is met, send out a game start message to all participants, with a randomly generated lobby ID
  """
  def handle_info(:after_user_join_lobby, socket) do
    # The `list` function returns presences for a topic.
    # The keys are user_ids
    existing_users = Map.keys(Presence.list(socket))

    if length(existing_users) >= @num_users_per_game do
      [user1_id | [user2_id | _]] = existing_users
      lounge_id = Ecto.UUID.generate()

      BABE.Endpoint.broadcast!("color_reference:user:#{user1_id}", "game_start", %{
        lounge_id: lounge_id,
        role: "speaker"
      })

      BABE.Endpoint.broadcast!("color_reference:user:#{user2_id}", "game_start", %{
        lounge_id: lounge_id,
        role: "listener"
      })

      # If the users leave the lobby channel on their own, don't think we need to manually remove them here.
      # Presence.untrack(socket, user1_id)
      # Presence.untrack(socket, user2_id)
      # IO.inspect(Presence.list(socket))
    end

    {:noreply, socket}
  end

  @doc """
  If the conditions are met (e.g. there are enough participants waiting in the lobby), the server tells selected participants to join a lounge to start the experiment.

  This function handles what happens when the participants send in the join request.
  """
  def join("color_reference:lounge:" <> lounge_id, _payload, socket) do
    existing_users = Map.keys(Presence.list(socket))
    IO.puts("lounge: #{lounge_id}")
    IO.inspect(Presence.list(socket))

    # Maybe there will be errors where somehow more users than intended try to join. We can only reject the last user if that's the case.
    if length(existing_users) >= @num_users_per_game do
      {:error, %{reason: "Game already full! Please refresh."}}
    else
      Presence.track(socket, socket.assigns.user_id, %{
        online_at: inspect(System.system_time(:second))
      })

      {:ok, socket}
    end
  end

  @doc """
  This handles new messages from the clients and broadcast them to everybody susbcribed to the same topic (i.e. who joined the same lounge).
  """
  def handle_in("new_msg", payload, socket) do
    broadcast(socket, "new_msg", payload)
    {:noreply, socket}
  end

  @doc """
  Also send just broadcast `next_round` messages to all the participants.
  """
  def handle_in("next_round", payload, socket) do
    broadcast(socket, "next_round", payload)
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # Currently not needed.
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end
end
