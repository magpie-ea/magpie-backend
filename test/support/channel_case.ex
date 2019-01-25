defmodule BABE.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest

      alias BABE.Repo
      alias BABE.ParticipantSocket
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import BABE.TestHelpers

      # The default endpoint for testing
      @endpoint BABE.Endpoint

      def create_and_subscribe_participant(experiment) do
        participant_id = Ecto.UUID.generate()

        {:ok, socket} =
          connect(ParticipantSocket, %{
            "participant_id" => participant_id,
            "experiment_id" => experiment.id
          })

        {:ok, _, _} = subscribe_and_join(socket, "participant:#{participant_id}")

        {:ok, socket: socket, experiment: experiment, participant_id: participant_id}
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BABE.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BABE.Repo, {:shared, self()})
    end

    :ok
  end
end
