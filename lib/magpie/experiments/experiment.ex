defmodule Magpie.Experiments.Experiment do
  @moduledoc """
  An Experiment corresponds to an experiment that the author plans to run. Each ExperimentResult and each ExperimentStatus must belong to an Experiment.
  """
  use MagpieWeb, :model

  schema "experiments" do
    field :name, :string, null: false
    field :author, :string, null: false

    # A randomly generated API token which the frontend should provide when interacting with the backend
    field :api_token, :string, null: false

    # Note that the type :text is actually used for Postgres (specified in the migration file). It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
    field :description, :string
    field :active, :boolean, default: true, null: false
    field :dynamic_retrieval_keys, {:array, :string}

    # Accumulation of columns contained in each result JSON submission.
    field :experiment_result_columns, {:array, :string}

    ### slots-related parts
    field :is_ulc, :boolean, default: true

    # ULC fields
    field :num_variants, :integer, null: true, default: 1
    field :num_chains, :integer, null: true, default: 1
    field :num_generations, :integer, null: true, default: 1
    field :num_players, :integer, null: true, default: 1

    # This field is indeed global to an experiment. Once it has incremented, there's no reason to decrement it again.
    field :copy_number, :integer, default: 0
    field :slot_ordering, {:array, :string}
    field :slot_statuses, :map
    field :slot_dependencies, :map
    field :slot_attempt_counts, :map
    field :trial_players, :map

    has_many(:experiment_results, Magpie.Experiments.ExperimentResult, on_delete: :delete_all)
    has_many(:experiment_statuses, Magpie.Experiments.ExperimentStatus, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :author,
      :description,
      :active,
      :dynamic_retrieval_keys,
      :experiment_result_columns,
      :slot_ordering,
      :slot_statuses,
      :slot_dependencies,
      :slot_attempt_counts,
      :trial_players,
      :copy_number
    ])
    |> validate_required([:name, :author])
  end

  # This is actually the changeset for ULC? Let's see.
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :author,
      :description,
      :active,
      :dynamic_retrieval_keys,
      :experiment_result_columns,
      :num_variants,
      :num_chains,
      :num_generations,
      :num_players,
      :is_ulc
    ])
    |> validate_required([:name, :author])
    |> validate_ulc_experiment_requirements()
    |> initialize_slot_fields()
  end

  defp validate_ulc_experiment_requirements(changeset) do
    if Ecto.Changeset.get_field(changeset, :is_ulc) do
      changeset
      |> validate_required([:num_variants, :num_chains, :num_generations, :num_players])
      |> validate_number(:num_variants, greater_than: 0)
      |> validate_number(:num_chains, greater_than: 0)
      |> validate_number(:num_generations, greater_than: 0)
      |> validate_number(:num_players, greater_than: 0)
    else
      changeset
    end
  end

  defp initialize_slot_fields(changeset) do
    changeset
    |> put_change(:slot_ordering, [])
    |> put_change(:slot_statuses, %{})
    |> put_change(:slot_dependencies, %{})
    |> put_change(:slot_attempt_counts, %{})
    |> put_change(:trial_players, %{})
  end
end
