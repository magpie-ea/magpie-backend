defmodule Magpie.ParticipantSocketTest do
  @moduledoc """
  Module for tests on the socket connection.
  """
  use Magpie.ChannelCase, async: true

  alias Magpie.ParticipantSocket

  test "connect with a valid experiment_id" do
    experiment = insert_ulc_experiment()

    assert {:ok, socket} =
             connect(ParticipantSocket, %{
               "participant_id" => "1234",
               "experiment_id" => experiment.id
             })

    # Assert the assigns as well
    assert socket.assigns.participant_id == "1234"
    assert socket.assigns.experiment_id == experiment.id
  end

  test "refuse connection with an invalid experiment_id" do
    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "1234",
               "experiment_id" => -1
             })
  end

  test "refuse connection without supplying experiment_id" do
    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "1234"
             })
  end

  test "refuse connection without supplying participant_id" do
    experiment = insert_ulc_experiment()

    assert :error =
             connect(ParticipantSocket, %{
               "experiment_id" => experiment.id
             })
  end

  test "refuse connection with an empty participant_id" do
    experiment = insert_ulc_experiment()

    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "",
               "experiment_id" => experiment.id
             })
  end
end
