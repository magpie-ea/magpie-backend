defmodule BABE.InteractiveLobbyChannel do
  @moduledoc """
  Channel for maintaining lobbies in experiments which require multiple participants to interact with each other.

  The client should make use of the presence_diff event to decide if a game can be started.
  """

  use BABE.Web, :channel
  alias BABE.Presence

  @doc """
  Let the participant join the lobby and wait in there.
  """
  def join("interactive_lobby:" <> experiment_id, payload, socket) do
    # The participant_id and the experiment_id should have been stored in the socket assigns already, and should match what the client tries to send us.
    if socket.assigns.participant_id == payload["participant_id"] &&
         socket.assigns.experiment_id == experiment_id do
      send(self(), :after_participant_join_lobby)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_participant_join_lobby, socket) do
    # Add this participant to the list of all participants waiting in the lobby of this experiment.
    # No point in using experiment_id as the key as there's one lobby per experiment.
    # Let me just make the following assumption: An interactive experiment must happen between participants of the same chain and realization.
    # If they need something more complicated in the future, change the structure by then.
    Presence.track(socket, "#{socket.assigns.chain}:#{socket.assigns.realization}", %{
      participant_id: socket.assigns.participant_id,
      variant: socket.assigns.variant,
      chain: socket.assigns.chain,
      realization: socket.assigns.realization
    })

    # Send the list of all participants currently connected to the lobby, and let them decide whether to perform the next step or not.
    # Note that this list includes this participant themselves.
    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end
