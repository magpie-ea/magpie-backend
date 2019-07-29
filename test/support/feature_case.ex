defmodule Magpie.FeatureCase do
  @moduledoc """
  Defines the test case to be used by feature tests, using Wallaby.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias Magpie.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Magpie.Router.Helpers
      import Magpie.TestHelpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Magpie.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Magpie.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Magpie.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
