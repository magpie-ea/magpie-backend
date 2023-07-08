defmodule Magpie.Repo.Migrations.AddApiTokenToExperiments do
  use Ecto.Migration

  def change do
    # execute(
    #   "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"",
    #   "DROP EXTENSION IF EXISTS \"pgcrypto\""
    # )

    alter table(:experiments) do
      add :api_token, :string, null: false, default: fragment("md5(random()::text)")
    end
  end
end
