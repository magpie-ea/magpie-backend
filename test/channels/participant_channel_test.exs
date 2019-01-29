defmodule BABE.ParticipantChannelTest do
  @moduledoc """
  Module for tests on the participant channel.
  """
  use BABE.ChannelCase

  # alias BABE.ParticipantChannel
  alias BABE.ParticipantSocket

  setup do
    experiment = insert_complex_experiment()
    create_and_subscribe_participant(experiment)
  end

  test "joins the participant channel successfully", %{
    socket: socket,
    experiment: _experiment,
    participant_id: participant_id
  } do
    assert {:ok, _, socket} = subscribe_and_join(socket, "participant:#{participant_id}")
  end

  test "Receives the trituple denoting the next available experiment slot after joining", %{
    socket: socket,
    experiment: _experiment,
    participant_id: participant_id
  } do
    {:ok, _, socket} = subscribe_and_join(socket, "participant:#{participant_id}")

    expected_message = %{
      variant: socket.assigns.variant,
      chain: socket.assigns.chain,
      realization: socket.assigns.realization
    }

    assert_broadcast("experiment_available", ^expected_message)
  end

  describe "submit_results" do
    test "Successfully stores experiment results", %{
      socket: socket,
      experiment: experiment,
      participant_id: participant_id
    } do
    end

    test "Successfully sets the ExperimentStatus to 2", %{
      socket: socket,
      experiment: experiment,
      participant_id: participant_id
    } do
    end

    # Probably better to put it in the IteratedLobbyChannelTest module
    test "Sends experiment results to all potential waiting clients", %{
      socket: socket,
      experiment: experiment,
      participant_id: participant_id
    } do
    end
  end
end
