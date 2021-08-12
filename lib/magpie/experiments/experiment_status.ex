defmodule Magpie.Experiments.ExperimentStatus do
  @moduledoc """
  Keeps track of the experiment status, where it can be open (0), in progress (1), or completed (2). Used for complex experiments.
  """
  use MagpieWeb, :model

  schema "experiment_statuses" do
    field(:variant, :integer, null: false)
    field(:chain, :integer, null: false)
    field(:generation, :integer, null: false)
    field(:player, :integer, null: false)

    # 0 means open (i.e. either not taken up or dropped). 1 means in progress. 2 means completed (submitted by the participant)
    field(:status, Ecto.Enum, values: [open: 0, in_progress: 1, completed: 2])

    belongs_to(:experiment, Magpie.Experiments.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:experiment_id, :variant, :chain, :generation, :player, :status])
    |> validate_required([:experiment_id, :variant, :chain, :generation, :player])
    |> validate_number(:variant, greater_than: 0)
    |> validate_number(:chain, greater_than: 0)
    |> validate_number(:generation, greater_than: 0)
    |> validate_number(:player, greater_than: 0)
    # Must be associated with an experiment
    |> assoc_constraint(:experiment)
  end
end
