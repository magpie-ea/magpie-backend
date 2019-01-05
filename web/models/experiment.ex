defmodule BABE.Experiment do
  @moduledoc """
  An Experiment corresponds to an experiment that the author plans to run. Each ExperimentResult and each ExperimentStatus must belong to an Experiment.
  """
  use BABE.Web, :model

  schema "experiments" do
    field(:name, :string)
    field(:author, :string)

    # Note that the type :text is actually used for Postgres (specified in the migration file). It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
    field(:description, :string)
    field(:active, :boolean, default: true, null: false)
    field(:current_submissions, :integer, default: 0, null: false)
    field(:dynamic_retrieval_keys, {:array, :string})

    # null: true because they can be null for simple experiments.
    field(:num_variants, :integer, null: true)
    field(:num_chains, :integer, null: true)
    field(:num_realizations, :integer, null: true)

    field(:is_complex, :boolean, default: false)

    has_many(:experiment_results, BABE.ExperimentResult, on_delete: :delete_all)
    has_many(:experiment_statuses, BABE.ExperimentStatus, on_delete: :delete_all)

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :author,
      :description,
      :active,
      :dynamic_retrieval_keys,
      :num_variants,
      :num_chains,
      :num_realizations,
      :is_complex
    ])
    |> validate_required([:name, :author, :active])
    |> validate_complex_experiment_requirements(params)
  end

  # If the experiment is complex, those three numbers must be present.
  defp validate_complex_experiment_requirements(changeset, %{"is_complex" => "true"}) do
    changeset
    |> validate_required([:num_variants, :num_chains, :num_realizations])
  end

  # On the contrary scenario, they must be absent.
  defp validate_complex_experiment_requirements(changeset, _) do
    changeset
    |> delete_change(:num_variants)
    |> delete_change(:num_chains)
    |> delete_change(:num_realizations)
  end
end
