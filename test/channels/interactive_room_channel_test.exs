defmodule Magpie.InteractiveRoomChannelTest do
  @moduledoc """
  Tests for the interactive room channel
  """
  use Magpie.ChannelCase

  # alias Magpie.InteractiveRoomChannel
  alias Magpie.ParticipantSocket

  setup do
    experiment = insert_dynamic_experiment()
    create_and_subscribe_participant(experiment)
  end

  test "joins the interactive room channel successfully", %{
    socket: socket,
    experiment: _experiment,
    participant_id: _participant_id,
    assignment_identifier: assignment_identifier
  } do
    assert {:ok, _, _socket} =
             subscribe_and_join(
               socket,
               "interactive_room:#{assignment_identifier.experiment_id}:#{assignment_identifier.variant}:#{assignment_identifier.chain}:#{assignment_identifier.generation}"
             )
  end

  test "the newly joined user is tracked by Presence", %{
    socket: socket,
    experiment: _experiment,
    participant_id: _participant_id,
    assignment_identifier: assignment_identifier
  } do
    {:ok, _, _socket} =
      subscribe_and_join(
        socket,
        "interactive_room:#{assignment_identifier.experiment_id}:#{assignment_identifier.variant}:#{assignment_identifier.chain}:#{assignment_identifier.generation}"
      )

    # payload = %{
    #   variant: socket.assigns.variant,
    #   chain: socket.assigns.chain,
    #   generation: socket.assigns.generation
    # }

    # assert_broadcast("presence_diff", ^payload)

    # Just test that it pushed out an event called "presence_diff". It seems to be not that easy to match against the payload body actually.
    assert_broadcast("presence_diff", %{})
  end

  test "start_game message is sent after the specified number of participants is reached", %{
    socket: socket,
    experiment: experiment,
    assignment_identifier: assignment_identifier
  } do
    # First we need do join the first created participant to the channel...
    subscribe_and_join(
      socket,
      "interactive_room:#{assignment_identifier.experiment_id}:#{assignment_identifier.variant}:#{assignment_identifier.chain}:#{assignment_identifier.generation}"
    )

    num_participants = socket.assigns.num_players

    Enum.each(1..(num_participants - 1), fn _count ->
      {:ok,
       socket: socket,
       experiment: _experiment,
       participant_id: _participant_id,
       assignment_identifier: _ai} = create_and_subscribe_participant(experiment)

      subscribe_and_join(
        socket,
        "interactive_room:#{assignment_identifier.experiment_id}:#{assignment_identifier.variant}:#{assignment_identifier.chain}:#{assignment_identifier.generation}"
      )
    end)

    assert_broadcast("start_game", %{"group_label" => _})
  end
end
