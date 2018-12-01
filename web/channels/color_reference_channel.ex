defmodule BABE.ColorReferenceChannel do
  use BABE.Web, :channel
  alias BABE.Presence
  import Ecto

  @num_users_per_game 2


  def join("color_reference:user:" <> user_id, _payload, socket) do
    if socket.assigns.user_id == user_id do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("color_reference:lobby", _payload, socket) do
    Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second))
    })

    send(self(), :after_user_join_lobby)
    {:ok, socket}
  end

  def join("color_reference:lounge:" <> lounge_id, _payload, socket) do
    existing_users = Map.keys(Presence.list(socket))
    IO.puts("lounge: #{lounge_id}")
    IO.inspect(Presence.list(socket))

    if length(existing_users) >= @num_users_per_game do
      {:error, %{reason: "Lounge already full! Please refresh."}}
    else
      Presence.track(socket, socket.assigns.user_id, %{
        online_at: inspect(System.system_time(:second))
      })
      {:ok, socket}
    end

  end

  # def join("color_reference:" <> lounge, payload, socket) do
  #   if authorized?(payload) do
  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "unauthorized"}}
  #   end
  # end

  @doc """
  What to do:
  - Check the number of users present in the lobby when a new user joins
  - If the target number (in most cases 2) is reached, send out game start message, with a randomly generated lobby ID
  - Probably should also just disconnect all the users in the lobby from the server side afterwards to avoid problems? Or maybe not. I might even define the function such that when the number of users connected somehow exceeds 2 (e.g. when the 2nd and the 3rd user join simultaneously), always select the first two presences and send messages to them. Might work let's see.
    Can also write a test about such cases.
  """
  def handle_info(:after_user_join_lobby, socket) do
    # The `list` function returns presences for a topic.

    existing_users = Map.keys(Presence.list(socket))
    IO.inspect(existing_users)

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

      # If the users leave the lobby channel already, don't think we need to manually remove them here.
      # Presence.untrack(socket, user1_id)
      # Presence.untrack(socket, user2_id)
      IO.inspect(Presence.list(socket))
    end

    # If the number of users in the lobby has reached the target number, start the game
    # Else track this current user as well
    # if length(Presence.list(socket)["in_lobby"][:metas]) > num_users_per_game - 1 do
    #   broadcast!(socket, "game_start", %{lounge: "asdf"})
    #   # send(dest, message)
    # else
    #   Presence.track(socket, "in_lobby", %{
    #     online_at: inspect(System.system_time(:second))
    #   })
    # end

    # :noreply seems to mean that we don't send any message/event to the client anyways.
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # Currently not needed.
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # It is also common to receive messages from the client and
  # broadcast to *everyone* in the current topic (color_reference:lounge_id).
  def handle_in("new_msg", payload, socket) do
    broadcast(socket, "new_msg", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # By default it just returns true.
  # We might be able to add some sort of authorization token, or we may just spare this step for now.
  defp authorized?(_payload) do
    true
  end
end
