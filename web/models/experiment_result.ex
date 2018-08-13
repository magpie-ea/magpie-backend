# Now it is actually better called "ExperimentResult", since I'll create another model for experiment management. But anyways let's keep it first?
defmodule BABE.ExperimentResult do
  @moduledoc """
  An ExperimentResult corresponds to a set of results obtained from one participant finishing one complete experiment, which usually consists of several trials.
  """

  use BABE.Web, :model

  schema "experiment_results" do
    # A map represents the whole JSON object received when the experiment was first submitted.
    # Maybe the name `data` would be more appropriate. But anyways. Don't want to have troubles with migrations so let's just keep it for now.
    # The map type will already be JSONB in Postgres by default. It will be simply TEXT in other DBs.
    # Now that we record JSON arrays, seems that we actually need to change the type to array of map.
    field(:results, {:array, :map})

    belongs_to(:experiment, BABE.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    # `cast/3` ignores all parameters not explicitly permitted, converts all permitted key names into atoms, and store them in the :changes field of the changeset
    # The point is that only the :changes field will work when performing any real DB action with Repo.
    # This is to say, the other parameters are not "deleted" at this step yet. You can chain multiple `cast` calls.
    |> cast(params, [:results, :experiment_id])
    |> validate_required([:results, :experiment_id])
    # Must be associated with an experiment
    |> assoc_constraint(:experiment)
  end
end
