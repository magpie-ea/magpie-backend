defmodule Magpie.Experiments do
  @moduledoc """
  Context for experiments
  """
  alias Magpie.Experiments.{Experiment, ExperimentResult, ExperimentStatus}
  alias Magpie.Repo

  alias Ecto.Multi
  import Ecto.Query
  import Magpie.Helpers

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
      # Just use reduce for everything. Jose's favorite anyways.
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

  def list_experiments do
    Experiment
    |> order_by(asc: :id)
    |> Repo.all()
  end

  def get_experiment(id) do
    Repo.get(Experiment, id)
  end

  def get_experiment!(id) do
    Repo.get!(Experiment, id)
  end

  def update_experiment(%Experiment{} = experiment, attrs) do
    experiment
    |> Experiment.changeset(attrs)
    |> Repo.update()
  end

  def delete_experiment!(%Experiment{} = experiment) do
    Repo.delete!(experiment)
  end

  @doc """
  Toggle experiment status between active and inactive
  """
  def toggle_experiment(%Experiment{} = experiment) do
    new_status = !experiment.active
    changeset = Ecto.Changeset.change(experiment, active: new_status)

    if new_status == false do
      reset_in_progress_experiment_statuses()
    end

    Repo.update(changeset)
  end

  def reset_experiment(%Experiment{} = experiment) do
    Multi.new()
    |> Multi.delete_all(:experiment_results, Ecto.assoc(experiment, :experiment_results))
    |> Multi.update_all(:experiment_statuses, Ecto.assoc(experiment, :experiment_statuses),
      set: [status: 0]
    )
    |> Repo.transaction()
  end

  def reset_in_progress_experiment_statuses do
    from(p in ExperimentStatus, where: p.status == 1)
    |> Repo.update_all(set: [status: 0])
  end

  @doc """
  Records one experiment submission
  """
  def create_experiment_result(experiment, results) do
    experiment
    # This creates an ExperimentResult struct with the :experiment_id field filled in
    |> Ecto.build_assoc(:experiment_results)
    |> ExperimentResult.changeset(%{"results" => results})
    |> Repo.insert()
  end

  def retrieve_experiment_results_as_csv(%Experiment{} = experiment) do
    experiment_submissions = Repo.all(Ecto.assoc(experiment, :experiment_results))

    case experiment_submissions do
      [] ->
        {:error, :no_submissions_yet}

      _ ->
        # Name the CSV file to be returned.
        {:ok, file_path} = Briefly.create()
        file = File.open!(file_path, [:write, :utf8])

        prepare_submissions_for_csv_download(experiment_submissions)
        # Enum.each because the CSV library returns a stream, with each row being an entry. We need to make the stream concrete with this step.
        |> Enum.each(&IO.write(file, &1))

        File.close(file)

        {:ok, file_path}
    end
  end

  # Writes the submissions to a CSV file.
  # Note that we have a validation in schemas to ensure that each entry in `results` must have the same set of keys. So the following code take take that as an assumption.
  defp prepare_submissions_for_csv_download(submissions) do
    # Fetch the keys from the first submission.
    with [submission | _] <- submissions,
         [trial | _] <- submission.results,
         keys <- Map.keys(trial) do
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
    else
      _ -> []
    end
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
      |> Enum.map(fn v -> format_value(v) end)
    end)
  end

  def retrieve_experiment_results_as_json(nil) do
    {:nil_experiment, true}
  end

  def retrieve_experiment_results_as_json(%Experiment{} = experiment) do
    with {:nil_keys, false} <- {:nil_keys, is_nil(experiment.dynamic_retrieval_keys)},
         experiment_results <- Repo.all(Ecto.assoc(experiment, :experiment_results)),
         {:empty_results, false} <- {:empty_results, Enum.empty?(experiment_results)} do
      {:ok, experiment_results}
    else
      error -> error
    end
  end
end
