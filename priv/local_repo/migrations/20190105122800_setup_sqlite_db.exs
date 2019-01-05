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

      add(:is_complex, :boolean, default: false)
      add(:num_variants, :integer, null: true)
      add(:num_chains, :integer, null: true)
      add(:num_realizations, :integer, null: true)

      timestamps()
    end

    create table(:experiment_results) do
      add(:experiment_id, references("experiments", on_delete: :delete_all))
      add(:results, {:array, :map}, null: false)
      add(:variant, :integer, null: true)
      add(:chain, :integer, null: true)
      add(:realization, :integer, null: true)

      timestamps()
    end

    create(index(:experiment_results, [:experiment_id]))

    create(
      index(:experiment_results, [:experiment_id, :variant, :chain, :realization], unique: true)
    )

    create table(:custom_records) do
      add(:name, :string)
      add(:record, {:array, :map})

      timestamps()
    end

    create table(:experiment_statuses) do
      add(:experiment_id, references("experiments", on_delete: :delete_all))
      add(:variant, :integer, null: false)
      add(:chain, :integer, null: false)
      add(:realization, :integer, null: false)
      # 0 means not taken up/dropped. 1 means in progress. 2 means submitted
      add(:status, :integer, default: 0, null: false)

      timestamps()
    end

    create(index(:experiment_statuses, [:experiment_id]))

    create(
      index(:experiment_statuses, [:experiment_id, :variant, :chain, :realization], unique: true)
    )
  end
end
