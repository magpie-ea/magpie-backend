defmodule BABE.Experiment do
  @moduledoc """
  An Experiment corresponds to an experiment that the author plans to run. They can decide whether to deactivate the experiment so that no new submissions will be accepted.
  """
  use BABE.Web, :model

  schema "experiments" do
    field :name, :string
    field :author, :string
    # Note that the type :text is actually used for Postgres (specified in the migration file). It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
    field :description, :string
    field :active, :boolean, default: false
    field :maximum_submissions, :integer
    field :current_submissions, :integer, default: 0, null: false
    field :dynamic_retrieval_keys, {:array, :string}

    has_many :experiment_results, BABE.ExperimentResult

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :author, :description, :active, :maximum_submissions, :dynamic_retrieval_keys])
    |> validate_required([:name, :author, :active])
  end

end
