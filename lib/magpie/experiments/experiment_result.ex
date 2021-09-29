defmodule Magpie.Experiments.ExperimentResult do
  @moduledoc """
  An ExperimentResult corresponds to a set of results obtained from one participant finishing one complete experiment, which usually consists of several trials.
  """

  @derive {Jason.Encoder, only: [:results]}

  use MagpieWeb, :model

  import Magpie.Helpers

  schema "experiment_results" do
    # A map represents the whole JSON object received when the experiment was first submitted.
    # The map type will already be JSONB in Postgres by default. It will be simply TEXT in other DBs.
    field(:results, {:array, :map}, null: false)
    field(:variant, :integer, null: true)
    field(:chain, :integer, null: true)
    field(:generation, :integer, null: true)
    field(:player, :integer, null: true)
    field(:is_intermediate, :boolean, default: false)

    belongs_to(:experiment, Magpie.Experiments.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [
      :results,
      :experiment_id,
      :variant,
      :chain,
      :generation,
      :player,
      :is_intermediate
    ])
    |> validate_required([:experiment_id, :results])
    |> validate_number(:variant, greater_than: 0)
    |> validate_number(:chain, greater_than: 0)
    |> validate_number(:generation, greater_than: 0)
    |> validate_number(:player, greater_than: 0)
    |> validate_change(:results, &check_record(&1, &2))
    |> assoc_constraint(:experiment)
  end
end
