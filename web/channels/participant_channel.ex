defmodule Magpie.ParticipantChannel do
  @moduledoc """
  Channel dedicated to keeping individual connections with each participant
  """

  use Magpie.Web, :channel
  alias Magpie.ChannelHelper
  alias Magpie.{Repo, ExperimentStatus, ExperimentResult}
  alias Ecto.Multi

  @doc """
  The first step after establishing connection for any participant is to log in with a (in most cases randomly generated in the frontend) participant_id
  """
  def join("participant:" <> participant_id, _payload, socket) do
    # The participant_id should have been stored in the socket assigns already, and should match what the client tries to send us.
    if socket.assigns.participant_id == participant_id do
      send(self(), :after_participant_join)

      :ok =
        Magpie.ChannelWatcher.monitor(
          :participants,
          self(),
          {__MODULE__, :handle_leave, [socket]}
        )

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Reset the experiment status when the user leaves halfway through (e.g. closes the tab)

  N.B.: This callback might not catch situations where the connection times out, etc. A GenServer as mentioned in https://stackoverflow.com/questions/33934029/how-to-detect-if-a-user-left-a-phoenix-channel-due-to-a-network-disconnect could be useful.
  """
  def handle_leave(socket) do
    experiment_status =
      ChannelHelper.get_experiment_status(
        socket.assigns.experiment_id,
        socket.assigns.variant,
        socket.assigns.chain,
        socket.assigns.realization
      )

    # We should only clear the ExperimentStatus to 0 if the participant left when the experiment was still in progress, i.e. not submitted.
    if experiment_status.status == 1 do
      changeset = experiment_status |> ExperimentStatus.changeset(%{status: 0})
      Repo.update!(changeset)
    end
  end

  def handle_info(:after_participant_join, socket) do
    # Broadcast the trituple <variant-nr, chain-nr, realization-nr> to the user.
    broadcast(socket, "experiment_available", %{
      variant: socket.assigns.variant,
      chain: socket.assigns.chain,
      realization: socket.assigns.realization
    })

    {:noreply, socket}
  end

  @doc """
  Record the submission when the client finishes the experiment. Set the experiment status to 2 (finished)

  We might still allow the submissions via the REST API anyways. Both should be viable options.
  """
  def handle_in("submit_results", payload, socket) do
    experiment_id = socket.assigns.experiment_id
    variant = socket.assigns.variant
    chain = socket.assigns.chain
    realization = socket.assigns.realization
    results = payload["results"]

    experiment_status =
      ChannelHelper.get_experiment_status(
        socket.assigns.experiment_id,
        socket.assigns.variant,
        socket.assigns.chain,
        socket.assigns.realization
      )

    experiment_status_changeset = experiment_status |> ExperimentStatus.changeset(%{status: 2})

    experiment_result_changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        %{
          experiment_id: experiment_id,
          results: results,
          variant: variant,
          chain: chain,
          realization: realization
        }
      )

    operation =
      Multi.new()
      |> Multi.update(:status, experiment_status_changeset)
      |> Multi.insert(:result, experiment_result_changeset)

    case Repo.transaction(operation) do
      {:ok, _} ->
        # No need to monitor this participant anymore
        Magpie.ChannelWatcher.demonitor(:participants, self())

        # Tell all clients that are waiting for results of this experiment that the experiment is finished, and send them the results.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{experiment_id}:#{variant}:#{chain}:#{realization}",
          "finished",
          %{results: results}
        )

        # Send a simple ack reply to the submitting client.
        {:reply, :ok, socket}

      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        {:reply, :error, socket}
    end
  end

  @doc """
  The client should send a "save_intermediate_progress" message at each step of the experiment, so that experiment progress will not be lost if the client drops out before the end.

  However, we'd still need to clarify how this exactly fits into our use cases. I'd imagine in most cases if the user drops out, the slot should be freed up again?

  Maybe we can still save it into the DB without impacting the complete results or something. let's see.

  TODO: I'll need to discuss it further with Michael before enabling this functionality. For now just comment out the code.
  """
  # def handle_in("save_intermediate_results", payload, socket) do
  #   experiment_id = socket.assigns.experiment_id
  #   variant = socket.assigns.variant
  #   chain = socket.assigns.chain
  #   realization = socket.assigns.realization
  #   intermediate_results = payload.intermediate_results

  #   # Wait I don't think we should literally commit to the DB at every step. Sure we might be able to do this but if the experiment proceeds extremely fast this might be unsustainable.
  #   # Instead we can just save it in the socket/Presence, and put it into the DB if the experiment abruptly ends for whatever reason.
  #   # Still it makes me wonder what the purpose is after all. The realization is not difficult, but how does it fit into the general flow of our use cases?
  #   changeset =
  #     ExperimentResult.changeset(%ExperimentResult{
  #       experiment_id: experiment_id,
  #       results: intermediate_results,
  #       variant: variant,
  #       chain: chain,
  #       realization: realization
  #     })

  #   case Repo.insert_or_update(changeset) do
  #     {:ok, _} ->
  #       # Send a simple ack reply
  #       {:reply, :ok, socket}

  #     {:error, _changeset} ->
  #       {:reply, :error, socket}
  #   end
  # end
end
