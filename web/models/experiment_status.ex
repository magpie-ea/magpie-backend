defmodule BABE.ExperimentStatus do
  @moduledoc """
  Keeps track of the experiment status, where it can be available/abandoned (0), in progress (1), or submitted (2). Used for complex experiments.
  """
  use BABE.Web, :model

  schema "experiment_statuses" do
    field(:variant, :integer, null: false)
    field(:chain, :integer, null: false)
    field(:realization, :integer, null: false)
    # 0 means not taken up/dropped. 1 means in progress. 2 means submitted
    field(:status, :integer, default: 0, null: false)

    belongs_to(:experiment, BABE.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:experiment_id, :variant, :chain, :realization, :status])
    |> validate_required([:experiment_id, :variant, :chain, :realization, :status])
    # Must be associated with an experiment
    |> assoc_constraint(:experiment)
  end
end
