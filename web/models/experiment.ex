defmodule BABE.Experiment do
  @moduledoc """
  An Experiment corresponds to an experiment that the author plans to run. They can decide whether to deactivate the experiment so that no new submissions will be accepted.
  """
  use BABE.Web, :model

  schema "experiments" do
    field(:name, :string)
    field(:author, :string)

    # Note that the type :text is actually used for Postgres (specified in the migration file). It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
    field(:description, :string)
    field(:active, :boolean, default: true, null: false)
    field(:maximum_submissions, :integer)
    field(:current_submissions, :integer, default: 0, null: false)
    field(:dynamic_retrieval_keys, {:array, :string})
    field(:is_interactive_experiment, :boolean, default: false)
    field(:num_participants_interactive_experiment, :integer, null: true)

    # Should they be null or by default 1? At least num_realizations should not be 1 by default IMO.
    field(:num_variants, :integer, null: true)
    field(:num_chains, :integer, null: true)
    # Let me just make it a large number by default.
    field(:num_realizations, :integer, null: true)

    # If an experiment is iterative, we only assign a participant to <variant-nr, chain-nr, realization-nr + 1> when <variant-nr, chain-nr, realization-nr> is submitted.
    field(:is_complex, :boolean, default: false)

    has_many(:experiment_results, BABE.ExperimentResult)

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
      :maximum_submissions,
      :dynamic_retrieval_keys,
      :is_interactive_experiment,
      :num_participants_interactive_experiment,
      :num_variants,
      :num_chains,
      :num_realizations,
      :is_complex
    ])
    |> validate_required([:name, :author, :active])
    |> validate_required_if_complex(params)
  end

  defp validate_required_if_complex(changeset, %{"is_complex" => "true"}) do
    changeset
    |> validate_required([:num_variants, :num_chains, :num_realizations])
  end

  defp validate_required_if_complex(changeset, _) do
    changeset
  end
end
