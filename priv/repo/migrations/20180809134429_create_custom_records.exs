defmodule BABE.Repo.Migrations.CreateCustomRecords do
  use Ecto.Migration

  def change do
    create table(:custom_records) do
      add :name, :string
      add :record, {:array, :map}

      timestamps()
    end

  end
end
