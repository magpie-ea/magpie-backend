defmodule Magpie.IteratedLobbyChannel do
  @moduledoc """
  Channel for maintaining lobbies for iterated experiments where new participants need to wait for previous participants to finish first.
  """
  use MagpieWeb, :channel
  alias Magpie.Experiments
  alias Magpie.Experiments.AssignmentIdentifier
  alias Magpie.Presence

  @doc """
  When there is temporarily no free slot, a participant will join a queue of participants waiting for the next slot to open up.
  """
  def join(
        "iterated_lobby",
        _payload,
        socket
      ) do
    send(self(), :after_participant_join)
    {:ok, socket}
  end

  def handle_info(:after_participant_join, socket) do
    # Add this participant to the global queue of all participants waiting for the next slot to open up.
    # How should we broadcast to only the next participant joining?
    # Should probably be the assignment identifier, actually.
    # Hmm... Wait a sec. Do I actually need presence tracking. I don't think I do? Let's think about it.
    # But yeah, if I don't track it, how do I know that if some user is not waiting anymore. Seems this would still be the most convenient API then. Let's see.
    # I have to say though, I do feel the design of the presence API to be somewhat cumbersome. Let's see if we can do better then. Let's see.
    # Oh yeah, silly me. Of course we'd still need to use a key. The key should be the experiment identifier itself, so that we can easily group all participants of this experiment, eh?
    # Mentally speaking, it's a bit draining to contain so much info in an identifier. I'm thinking whether it would simply be possible to abstract away all the other infos, and keep the "identifier" itself pure. But it's annoying isn't it. Let's see then. Let's see.
    # Yeah, just the experiment id would suffice here. That's the point here.
    Presence.track(
      socket,
      "waiting_room:#{socket.assigns.experiment_id}",
      %{
        participant_id: socket.assigns.participant_id,
        online_at: inspect(System.system_time(:second))
      }
    )
  end

  def handle_info(
        {:after_participant_join, %AssignmentIdentifier{} = assignment_identifier},
        socket
      ) do
    experiment_status = Experiments.get_experiment_status(assignment_identifier)

    case experiment_status.status do
      :completed ->
        experiment_results =
          Experiments.get_one_experiment_results_for_identifier(assignment_identifier)

        # The same as what we do when the waited-on participant submits their results, send the results to all participants waiting for this participant.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{AssignmentIdentifier.to_string(assignment_identifier)}",
          "finished",
          %{results: experiment_results.results}
        )

        {:noreply, socket}

      # I'm not sure if there's a valid case of waiting on an experiment whose status is 0. But I guess I should handle reassignments of dropouts elsewhere.
      _ ->
        {:noreply, socket}
    end
  end
end
