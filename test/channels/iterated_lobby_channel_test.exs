defmodule Magpie.IteratedLobbyChannelTest do
  @moduledoc """
  Test for the iterated lobby channel
  """
  use Magpie.ChannelCase

  alias Magpie.ParticipantSocket
  # alias Magpie.IteratedLobbyChannel
  alias Magpie.ChannelHelper
  alias Magpie.ExperimentStatus

  setup do
    experiment = insert_complex_experiment()
    create_and_subscribe_participant(experiment)
  end

  test "joins the iterated lobby channel successfully", %{
    socket: socket,
    experiment: experiment,
    participant_id: _participant_id
  } do
    assert {:ok, _, socket} =
             subscribe_and_join(
               socket,
               "iterated_lobby:#{experiment.id}:#{socket.assigns.variant}:#{socket.assigns.chain}:#{
                 socket.assigns.realization
               }"
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
  #         socket.assigns.realization
  #       }"
  #     )

  #   experiment_status =
  #     ChannelHelper.get_experiment_status(
  #       experiment.id,
  #       socket.assigns.variant,
  #       socket.assigns.chain,
  #       socket.assigns.realization
  #     )

  #   insert_experiment_result(%{"experiment_id" => experiment.id})

  #   experiment_status
  #   |> ExperimentStatus.changeset(%{status: 2})
  #   |> Repo.update!()

  #   assert_broadcast("finished", %{})
  # end
end
