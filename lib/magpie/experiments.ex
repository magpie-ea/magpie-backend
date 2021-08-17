defmodule Magpie.Experiments do
  @moduledoc """
  Context for experiments
  """
  alias Magpie.Experiments.{AssignmentIdentifier, Experiment, ExperimentResult, ExperimentStatus}
  alias Magpie.Repo

  alias Ecto.Multi
  import Ecto.Query
  import Magpie.Helpers

  require Logger

  def create_experiment(experiment_params) do
    changeset_experiment = Experiment.changeset(%Experiment{}, experiment_params)

    changeset_experiment
    |> create_experiment_make_multi_with_insert()
    |> Repo.transaction()
  end

  defp create_experiment_make_multi_with_insert(changeset_experiment) do
    Multi.new()
    |> Multi.insert(:experiment, changeset_experiment)
    |> Multi.merge(fn %{experiment: experiment} ->
      # TODO: Of course we should be able to use insert_all... But this could be left as a further improvement I guess.
      Enum.reduce(1..experiment.num_variants, Multi.new(), fn variant, multi ->
        Enum.reduce(1..experiment.num_chains, multi, fn chain, multi ->
          Enum.reduce(1..experiment.num_generations, multi, fn generation, multi ->
            Enum.reduce(1..experiment.num_players, multi, fn player, multi ->
              params = %{
                experiment_id: experiment.id,
                variant: variant,
                chain: chain,
                generation: generation,
                player: player,
                status: 0
              }

              changeset = ExperimentStatus.changeset(%ExperimentStatus{}, params)

              multi
              |> Multi.insert(
                String.to_atom("experiment_status_#{chain}_#{variant}_#{generation}_#{player}"),
                changeset
              )
            end)
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

    Repo.update(changeset)
  end

  def reset_experiment(%Experiment{} = experiment) do
    Multi.new()
    |> Multi.delete_all(:experiment_results, Ecto.assoc(experiment, :experiment_results))
    |> Multi.update_all(:experiment_statuses, Ecto.assoc(experiment, :experiment_statuses),
      set: [status: :open]
    )
    |> Repo.transaction()
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

  def submit_experiment(experiment_id, results) do
    with experiment when not is_nil(experiment) <- get_experiment(experiment_id),
         true <- experiment.active,
         {:ok, _} <- create_experiment_result(experiment, results) do
      :ok
    else
      nil -> {:error, :experiment_not_found}
      false -> {:error, :experiment_inactive}
      {:error, %Ecto.Changeset{} = _changeset} -> {:error, :unprocessable_entity}
    end
  end

  def check_experiment_valid(experiment_id) do
    with experiment when not is_nil(experiment) <- get_experiment(experiment_id),
         true <- experiment.active do
      :ok
    else
      nil -> {:error, :experiment_not_found}
      false -> {:error, :experiment_inactive}
    end
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

  @doc """
  Releases complex experiments that have been taken up by some participant
  but for which the participant hasn't sent a heartbeat message for over 2 minutes.
  """
  def reset_statuses_for_inactive_complex_experiments do
    # Logger.info("Resetting statuses for inactive complex experiments.")

    two_minutes_ago = DateTime.add(DateTime.utc_now(), -120, :second)

    query =
      from es in ExperimentStatus,
        where: es.status == :in_progress,
        where: es.last_heartbeat < ^two_minutes_ago

    Repo.update_all(query, set: [status: :open])
  end

  @doc """
  Fetch experiment status with the given identifiers.
  """
  def get_experiment_status(%AssignmentIdentifier{} = assignment_identifier) do
    query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^assignment_identifier.experiment_id,
        where: s.variant == ^assignment_identifier.variant,
        where: s.chain == ^assignment_identifier.chain,
        where: s.generation == ^assignment_identifier.generation,
        where: s.player == ^assignment_identifier.player
      )

    Repo.one!(query)
  end

  @doc """
  Used when a participant breaks out, resulting in it being impossible to complete the experiment.

  Note that if the other participant already submitted their results, we wouldn't reset the statuses.
  """
  def reset_in_progress_assignments_for_interactive_exp(
        %AssignmentIdentifier{} = assignment_identifier
      ) do
    relevant_in_progress_experiment_statuses =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^assignment_identifier.experiment_id,
        where: s.chain == ^assignment_identifier.chain,
        where: s.variant == ^assignment_identifier.variant,
        where: s.generation == ^assignment_identifier.generation,
        where: s.status == :in_progress
      )

    Repo.update_all(relevant_in_progress_experiment_statuses, set: [status: :open])
  end

  def submit_and_complete_assignment_for_interactive_exp(
        %AssignmentIdentifier{} = assignment_identifier,
        results
      ) do
    relevant_experiment_statuses =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^assignment_identifier.experiment_id,
        where: s.chain == ^assignment_identifier.chain,
        where: s.variant == ^assignment_identifier.variant,
        where: s.generation == ^assignment_identifier.generation
      )

    experiment_result_changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        %{
          experiment_id: assignment_identifier.experiment_id,
          results: results,
          chain: assignment_identifier.chain,
          variant: assignment_identifier.variant,
          generation: assignment_identifier.generation,
          player: assignment_identifier.player,
          is_intermediate: false
        }
      )

    Multi.new()
    |> Multi.update_all(:experiment_statuses, relevant_experiment_statuses,
      set: [status: :completed]
    )
    |> Multi.insert(:experiment_result, experiment_result_changeset)
    |> Repo.transaction()
  end

  def save_intermediate_experiment_results(
        %AssignmentIdentifier{} = assignment_identifier,
        intermediate_results
      ) do
    experiment_result_changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        %{
          experiment_id: assignment_identifier.experiment_id,
          results: intermediate_results,
          chain: assignment_identifier.chain,
          variant: assignment_identifier.variant,
          generation: assignment_identifier.generation,
          player: assignment_identifier.player,
          is_intermediate: true
        }
      )

    Repo.insert(experiment_result_changeset)
  end

  @doc """
  Fetch all experiment results with the given identifier (could be more than one due to multiple submissions).
  """
  def get_all_experiment_results_for_identifier(%AssignmentIdentifier{} = assignment_identifier) do
    query =
      Ecto.Query.from(er in ExperimentResult,
        where: er.experiment_id == ^assignment_identifier.experiment_id,
        where: er.variant == ^assignment_identifier.variant,
        where: er.chain == ^assignment_identifier.chain,
        where: er.generation == ^assignment_identifier.generation,
        where: er.player == ^assignment_identifier.player,
        where: er.is_intermediate == false
      )

    Repo.all(query)
  end

  @doc """
  Just take the first one out of the potential list of results.
  """
  def get_one_experiment_results_for_identifier(%AssignmentIdentifier{} = assignment_identifier) do
    hd(get_all_experiment_results_for_identifier(assignment_identifier))
  end

  def get_next_available_assignment(experiment_id) do
    # This could be a bit slow but I hope it will still be efficient enough. The participant can wait.
    query =
      Ecto.Query.from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment_id,
        where: s.status == :open,
        # First by variant, then by chain, then by generation, then by player. In this way player gets incremented first and generation second.
        order_by: [s.variant, s.chain, s.generation, s.player],
        limit: 1
      )

    # Will produce nil in the case of empty list of results.
    List.first(Repo.all(query))
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
