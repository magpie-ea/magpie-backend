defmodule Magpie.Repo.Migrations.CreateExperimentStatuses do
  use Ecto.Migration

  def change do
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

    alter table(:experiments) do
      # Should they be null by default?
      add(:num_variants, :integer, null: true)
      add(:num_chains, :integer, null: true)
      add(:num_realizations, :integer, null: true)

      # If an experiment is complex, we assign a <variant-nr, chain-nr, realization-nr> tuple to each participant.
      add(:is_complex, :boolean, default: false)
    end

    # Enable targeted querying for situations like iterated experiments where the participant might only be interested in results from the previous realization of the same chain.
    alter table(:experiment_results) do
      # We might want to keep compatability with earlier experiments that were written without the socket connection in mind.
      # Therefore the following columns are nullable, i.e. traditional submissions via POST are acceptable. But we'll throw an error if somebody tries to query such results by the trituple.
      add(:variant, :integer, null: true)
      add(:chain, :integer, null: true)
      add(:realization, :integer, null: true)
    end

    # When querying particular results, all four pieces of info need to be provided.
    # Make this unique anyways. There should be only one set of canonical experiment results for a given combination overall. If we record temorary results, we should probably use another dedicated table anyways.

    # UPDATE 2020-01-03: Now that we want to record aborted experiment results as well, this should not be unique anymore. It's changed in a new migration.
    create(
      index(:experiment_results, [:experiment_id, :variant, :chain, :realization], unique: true)
    )
  end
end
