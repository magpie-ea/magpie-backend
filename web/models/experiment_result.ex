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
    # Actually I'm not even sure if null: false will stop empty JSONs. Probably will need to perform a check at controller level anyways. (DONE)
    # OK I think I can check for it forcefully with a manual check. What's the least bit of trouble with that? Nonsensical thoughts eh?
    field(:results, {:array, :map}, null: false)
    field(:variant, :integer, null: true)
    field(:chain, :integer, null: true)
    field(:realization, :integer, null: true)

    belongs_to(:experiment, BABE.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    # `cast/3` ignores all parameters not explicitly permitted, converts all permitted key names into atoms, and store them in the :changes field of the changeset
    # Only the :changes field will work when performing any real DB action with Repo.
    # This is to say, the other parameters are not "deleted" at this step yet. You can chain multiple `cast` calls.
    |> cast(params, [:results, :experiment_id, :variant, :chain, :realization])
    |> validate_required([:experiment_id, :results])
    |> validate_change(:results, &check_results(&1, &2))
    # Must be associated with an experiment
    |> assoc_constraint(:experiment)
  end

  defp check_results(_atom, results) do
    # First check if the results are empty
    if Enum.empty?(results) do
      [results: "cannot be empty"]
    else
      # Then check whether each map in the array has the same keys
      case contain_the_same_keys?(results) do
        false -> [results: "every entry must have the same set of keys"]
        true -> []
      end
    end
  end

  defp contain_the_same_keys?(results) do
    all_keys =
      results
      |> Enum.map(fn result -> Enum.sort(Map.keys(result)) end)

    first_keys = hd(all_keys)

    Enum.reduce(all_keys, first_keys, fn keys, problem_free ->
      problem_free && keys == first_keys
    end)
  end
end
