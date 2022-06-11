defmodule Magpie.Repo.Migrations.UseGraphBasedFieldsOnExperiments do
  use Ecto.Migration

  def change do
    alter table(:experiments) do
      add :is_ulc, :boolean, default: true
      add :copy_number, :integer, default: 0
      add :slot_ordering, {:array, :string}
      add :slot_statuses, :map
      add :slot_dependencies, :map
      add :slot_attempt_counts, :map
    end
  end
end