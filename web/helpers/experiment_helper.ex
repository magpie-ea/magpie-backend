defmodule BABE.ExperimentHelper do
  @moduledoc """
  Stores the helper functions which help to store and retrieve the experiments.
  """

  alias BABE.{ExperimentStatus, Experiment}
  alias Ecto.Multi
  alias BABE.Repo
  require Ecto.Query

  # Note that we have a validation in schemas to ensure that each entry in `results` must have the same set of keys. So the following code take take that as an assumption.
  @doc """
  Write the submissions to a CSV file.
  """
  def prepare_submissions_for_csv_download(submissions) do
    # Fetch the keys from the first submission.
    [submission | _] = submissions
    [trial | _] = submission.results
    keys = Map.keys(trial)

    # We need to prepend an additional column which contains uid in the output
    keys = ["submission_id" | keys]

    # The list `outputs` contains all rows of the resulting CSV file.
    # The first row will be the keys, i.e. headers
    outputs = [keys]

    # For each submission, get the results and concatenate it to the `outputs` list.
    outputs =
      outputs ++
        List.foldl(submissions, [], fn submission, acc ->
          acc ++ format_submission(submission, keys)
        end)

    # Note that the separator defaults to \r\n just to be safe
    outputs |> CSV.encode()
  end

  # For each trial recorded in this one experimentresult, ensure the proper key order is used to extract values.
  defp format_submission(submission, keys) do
    # Essentially this is just reordering.
    Enum.map(submission.results, fn trial ->
      # Inject the column "submission_id"
      trial = Map.put(trial, "submission_id", submission.id)
      # For each trial, use the order specified by keys
      keys
      |> Enum.map(fn k -> trial[k] end)
      # This is processing done when one of fields is an array. Though this type of submission should be discouraged.
      # Now I dont' think this should ever happen with the schema validations in place.
      |> Enum.map(fn v ->
        if is_list(v) do
          Enum.join(v, "|")
        else
          v
        end
      end)
    end)
  end

  @doc """
  Helper function to create an experiment. In Phoenix >= 1.3 should be part of the context module instead of the controller module.
  """
  def create_experiment(experiment_params) do
    changeset_experiment = Experiment.changeset(%Experiment{}, experiment_params)

    # This check is a bit clunky but currently we can only go this way as we don't have a separate ComplexExperiment model yet.
    multi =
      if Map.has_key?(changeset_experiment.changes, :is_complex) &&
           changeset_experiment.changes.is_complex do
        create_experiment_make_multi_with_insert(changeset_experiment)
      else
        Multi.new()
        |> Multi.insert(:experiment, changeset_experiment)
      end

    Repo.transaction(multi)
  end

  defp create_experiment_make_multi_with_insert(changeset_experiment) do
    Multi.new()
    |> Multi.insert(:experiment, changeset_experiment)
    |> Multi.merge(fn %{experiment: experiment} ->
      Enum.reduce(1..experiment.num_variants, Multi.new(), fn variant, multi ->
        Enum.reduce(1..experiment.num_chains, multi, fn chain, multi ->
          Enum.reduce(1..experiment.num_realizations, multi, fn realization, multi ->
            params = %{
              experiment_id: experiment.id,
              variant: variant,
              chain: chain,
              realization: realization,
              status: 0
            }

            changeset = ExperimentStatus.changeset(%ExperimentStatus{}, params)

            multi
            |> Multi.insert(
              String.to_atom("experiment_status_#{variant}_#{chain}_#{realization}"),
              changeset
            )
          end)
        end)
      end)
    end)
  end

  def reset_in_progress_experiment_statuses do
    Ecto.Query.from(p in ExperimentStatus, where: p.status == 1)
    |> Repo.update_all(set: [status: 0])
  end
end
