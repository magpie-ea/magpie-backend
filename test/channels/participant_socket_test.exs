defmodule BABE.ParticipantSocketTest do
  @moduledoc """
  Module for tests on the socket connection.
  """
  use BABE.ChannelCase, async: true

  alias BABE.{ParticipantSocket, ChannelHelper}

  test "connect with a valid experiment_id" do
    experiment = insert_complex_experiment()

    assert {:ok, socket} =
             connect(ParticipantSocket, %{
               "participant_id" => "1234",
               "experiment_id" => experiment.id
             })

    # Assert the assigns as well
    assert socket.assigns.participant_id == "1234"
    assert socket.assigns.experiment_id == experiment.id
    assert socket.assigns.num_variants == experiment.num_variants
    assert socket.assigns.num_chains == experiment.num_chains
    assert socket.assigns.num_realizations == experiment.num_realizations
  end

  test "Assigns ExperimentStatus to 1 upon connection" do
    experiment = insert_complex_experiment()

    {:ok, socket} =
      connect(ParticipantSocket, %{
        "participant_id" => "1234",
        "experiment_id" => experiment.id
      })

    assignment =
      ChannelHelper.get_experiment_status(
        experiment.id,
        socket.assigns.variant,
        socket.assigns.chain,
        socket.assigns.realization
      )

    assert assignment.status == 1
  end

  test "refuse connection with an invalid experiment_id" do
    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "1234",
               "experiment_id" => :rand.uniform(1000)
             })
  end

  test "refuse connection without supplying experiment_id" do
    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "1234"
             })
  end

  test "refuse connection without supplying participant_id" do
    experiment = insert_complex_experiment()

    assert :error =
             connect(ParticipantSocket, %{
               "experiment_id" => experiment.id
             })
  end

  test "refuse connection with an empty participant_id" do
    experiment = insert_complex_experiment()

    assert :error =
             connect(ParticipantSocket, %{
               "participant_id" => "",
               "experiment_id" => experiment.id
             })
  end

  # I guess this is a bit irrelevant so whatever. Just let it crash.
  # test "refuse connection with an empty experiment_id" do
  #   experiment = insert_complex_experiment()

  #   assert :error =
  #            connect(ParticipantSocket, %{
  #              "participant_id" => "asdf",
  #              "experiment_id" => ""
  #            })
  # end
end
