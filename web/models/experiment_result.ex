defmodule Magpie.ExperimentResult do
  @moduledoc """
  An ExperimentResult corresponds to a set of results obtained from one participant finishing one complete experiment, which usually consists of several trials.
  """

  use Magpie.Web, :model

  import Magpie.ModelHelper

  schema "experiment_results" do
    # A map represents the whole JSON object received when the experiment was first submitted.
    # The map type will already be JSONB in Postgres by default. It will be simply TEXT in other DBs.
    field(:results, {:array, :map}, null: false)
    field(:variant, :integer, null: true)
    field(:chain, :integer, null: true)
    field(:realization, :integer, null: true)

    belongs_to(:experiment, Magpie.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:results, :experiment_id, :variant, :chain, :realization])
    |> validate_required([:experiment_id, :results])
    |> validate_change(:results, &check_record(&1, &2))
    |> assoc_constraint(:experiment)
  end
end
