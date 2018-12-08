defmodule BABE.InteractiveExperimentChannel do
  @moduledoc """
  Channel for the communication between participants in interactive experiments
  """

  use BABE.Web, :channel
  alias BABE.Presence
  alias BABE.{Repo, Experiment}

  @doc """
  The first step after establishing connection for any participant is to log in with a (in most cases randomly generated in the frontend) participant_id
  """
  def join("interactive_experiment:participant:" <> participant_id, _payload, socket) do
    if socket.assigns.participant_id == participant_id do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  After a participant successfully logs in, they should join the lobby to wait for other participants to start a game.

  Each experiment has a designated lobby. Only those experiments with their ":is_interactive_experiment" attribute explicitly turned on will be allowed.
  """
  def join("interactive_experiment:lobby:" <> experiment_id, _payload, socket) do
    experiment = Repo.get(Experiment, experiment_id)

    case experiment do
      nil ->
        {:error, %{reason: "The experiment with the given id doesn't exist."}}

      _ ->
        case experiment.is_interactive_experiment do
          false ->
            {:error, %{reason: "The experiment is not marked as an interactive experiment."}}

          true ->
            # Tracks the newly joined participant.
            Presence.track(socket, socket.assigns.participant_id, %{
              online_at: inspect(System.system_time(:second))
            })

            # Trigger the condition checks in :after_participant_join_lobby
            send(
              self(),
              {:after_participant_join_lobby, experiment.num_participants_interactive_experiment}
            )

            {:ok, socket}
        end
    end
  end

  @doc """
  After a participant joins the lobby, check the target condition (e.g. num_waiting_participants>=2). If the condition is met, send out a game start message to all participants, with a randomly generated lobby ID.

  Currently, if more complex conditions than num_participants are desired, the frontend needs to perform the check, unless the participant of _babe modifies the backend code themselves.
  """
  def handle_info({:after_participant_join_lobby, num_participants}, socket) do
    # The `list` function returns presences for a topic.
    # Note that here the topic should already include the specific experiment itself
    # The keys are participant_ids
    existing_participants = Map.keys(Presence.list(socket))

    if length(existing_participants) >= num_participants do
      lounge_id = Ecto.UUID.generate()

      # Tell each participant to start the game and join the specified lounge, together with their position in the participants queue. Roles can then be assigned based on the position.
      existing_participants
      |> Enum.take(num_participants)
      |> Enum.with_index()
      |> Enum.each(fn {participant_id, counter} ->
        BABE.Endpoint.broadcast!(
          "interactive_experiment:participant:#{participant_id}",
          "game_start",
          %{
            lounge_id: lounge_id,
            nth_participant: counter
          }
        )
      end)
    end

    {:noreply, socket}
  end

  @doc """
  If the conditions are met (e.g. there are enough participants waiting in the lobby), the server tells selected participants to join a lounge to start the experiment.

  This function handles what happens when the participants send in the join request.
  """
  def join("interactive_experiment:lounge:" <> lounge_id, _payload, socket) do
    existing_participants = Map.keys(Presence.list(socket))

    # Sometimes maybe there will somehow be more participants than intended who try to join. We can only reject the last participant if that's the case.
    if length(existing_participants) >= @num_participants_per_game do
      {:error, %{reason: "Game already full! Please refresh."}}
    else
      Presence.track(socket, socket.assigns.participant_id, %{
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

  # Also send just broadcast `next_round` messages to all the participants.
  # Well it doesn't hurt to have a next_round event anyways. The frontend can always decide whether to use this event or just use the more generic new_msg event.
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
