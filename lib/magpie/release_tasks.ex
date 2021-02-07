defmodule Magpie.ReleaseTasks do
  @moduledoc """
  Release tasks
  """
  alias Ecto.Migrator

  def db_migrate do
    Application.load(:magpie)
    Application.ensure_all_started(:ssl)
    {:ok, _, _} = Migrator.with_repo(Magpie.Repo, &Migrator.run(&1, :up, all: true))
  end
end
