defmodule BABE.FeatureCase do
  @moduledoc """
  Defines the test case to be used by feature tests, using Wallaby.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias BABE.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import BABE.Router.Helpers
      import BABE.TestHelpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BABE.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BABE.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(BABE.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
