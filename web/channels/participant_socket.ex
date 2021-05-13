defmodule Magpie.ParticipantSocket do
  alias Magpie.{Repo, Experiment, ExperimentStatus, ChannelHelper}

  require Ecto.Query
  require Logger

  use Phoenix.Socket

  ## Channels
  # The ":*" part just means that any event with `participant` topic will be sent to the Participant channel.

  # Participant Channel is responsible for holding 1-to-1 connections with each participant.
  channel("participant:*", Magpie.ParticipantChannel)

  # Interactive room is for interactive experiments where multiple participants are present.
  channel("interactive_room:*", Magpie.InteractiveRoomChannel)

  # Iterated lobby is for iterated experiments where future generations need to wait on results from previous generations.
  channel("iterated_lobby:*", Magpie.IteratedLobbyChannel)

  ## Transports
  transport(:websocket, Phoenix.Transports.WebSocket,
    # Ensures idle connections are closed by the app before the 55 second timeout window of Heroku.
    timeout: 45_000
  )

  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a participant. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :participant_id, verified_participant_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  # def connect(_params, socket) do
  #   {:ok, socket}
  # end

  # The "participant_id" is just a string randomly generated by the frontend to uniquely identify the participant. We don't have registration mechanisms for the participants for now.
  def connect(%{"participant_id" => participant_id, "experiment_id" => experiment_id}, socket) do
    with false <- participant_id == "",
         experiment <- Repo.get(Experiment, experiment_id),
         false <- is_nil(experiment),
         true <- experiment.active,
         [next_assignment | _] <- ChannelHelper.get_all_available_assignments(experiment_id) do
      Logger.log(
        :info,
        "participant with id #{participant_id} is joining. They are assigned the assignment with chain #{
          next_assignment.chain
        }, realization #{next_assignment.realization}, variant #{next_assignment.variant}"
      )

      # Mark this assignment as "in progress", i.e. allocated to this participant.
      changeset =
        next_assignment
        |> ExperimentStatus.changeset(%{status: 1})

      case Repo.update(changeset) do
        {:ok, _} ->
          # The second item to return is the socket. We need to add assigns to the socket before returning it.
          {:ok,
           socket
           |> assign(:participant_id, participant_id)
           |> assign(:experiment_id, experiment_id)
           |> assign(:variant, next_assignment.variant)
           |> assign(:chain, next_assignment.chain)
           |> assign(:realization, next_assignment.realization)
           |> assign(:num_variants, experiment.num_variants)
           |> assign(:num_chains, experiment.num_chains)
           |> assign(:num_realizations, experiment.num_realizations)}

        {:error, _} ->
          :error
      end
    else
      # It seems that socket doesn't allow for sending specialized error messages. Just send :error
      _ -> :error
    end
  end

  # The incoming payload doesn't have the participant_id and experiment_id fields. Reject connection.
  def connect(_params, _socket), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given participant:
  #
  #     def id(socket), do: "participants_socket:#{socket.assigns.participant_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given participant:
  #
  #     Magpie.Endpoint.broadcast("participants_socket:#{participant.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
