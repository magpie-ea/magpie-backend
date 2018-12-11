defmodule BABE.Repo.Migrations.SetupSqliteDb do
  @moduledoc """
  Due to SQLite migration constraints, the original migrations for Postgres cannot be used in this case. Just start anew with a whole migration file.
  """
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add(:name, :string)
      add(:author, :string)
      add(:description, :string)
      add(:active, :boolean, default: true, null: false)
      add(:maximum_submissions, :integer)
      add(:current_submissions, :integer, default: 0, null: false)
      add(:dynamic_retrieval_keys, {:array, :string})
      add(:is_interactive_experiment, :boolean, default: false)
      add(:num_participants_interactive_experiment, :integer, null: true)

      timestamps()
    end

    create(index(:experiments, [:name]))
    create(index(:experiments, [:author]))

    create table(:experiment_results) do
      add(:experiment_id, references("experiments", on_delete: :delete_all))
      add(:results, {:array, :map}, null: false)

      timestamps()
    end

    create(index(:experiment_results, [:experiment_id]))

    create table(:custom_records) do
      add(:name, :string)
      add(:record, {:array, :map})

      timestamps()
    end
  end
end
