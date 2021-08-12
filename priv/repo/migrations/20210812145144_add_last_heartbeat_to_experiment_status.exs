defmodule Magpie.Repo.Migrations.AddLastHeartbeatToExperimentStatus do
  use Ecto.Migration

  def change do
    alter table(:experiment_statuses) do
      add :last_heartbeat, :utc_datetime, null: true
    end
  end
end
