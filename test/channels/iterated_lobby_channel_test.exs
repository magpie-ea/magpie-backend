defmodule Magpie.IteratedLobbyChannelTest do
  @moduledoc """
  Test for the iterated lobby channel
  """
  use Magpie.ChannelCase

  alias Magpie.ParticipantSocket

  setup do
    experiment = insert_dynamic_experiment()
    create_and_subscribe_participant(experiment)
  end

  test "joins the iterated lobby channel successfully", %{
    socket: socket,
    participant_id: _participant_id,
    assignment_identifier: assignment_identifier
  } do
    assert {:ok, _, _socket} =
             subscribe_and_join(
               socket,
               "iterated_lobby:#{assignment_identifier.experiment_id}:#{assignment_identifier.variant}:#{assignment_identifier.chain}:#{assignment_identifier.generation}:#{assignment_identifier.player}"
             )
  end

  # test "successfully gets the experiment result if the corresponding ExperimentStatus is 2", %{
  #   socket: socket,
  #   experiment: experiment,
  #   participant_id: _participant_id
  # } do
  #   {:ok, _, socket} =
  #     subscribe_and_join(
  #       socket,
  #       "iterated_lobby:#{experiment.id}:#{socket.assigns.variant}:#{socket.assigns.chain}:#{
  #         socket.assigns.generation
  #       }"
  #     )

  #   experiment_status =
  #     Experiments.get_experiment_status(
  #       experiment.id,
  #       socket.assigns.variant,
  #       socket.assigns.chain,
  #       socket.assigns.generation
  #     )

  #   insert_experiment_result(%{"experiment_id" => experiment.id})

  #   experiment_status
  #   |> ExperimentStatus.changeset(%{status: :completed})
  #   |> Repo.update!()

  #   assert_broadcast("finished", %{})
  # end
end
