defmodule Magpie.Experiments do
  @moduledoc """
  Context for experiments
  """
  alias Magpie.Experiments.{
    AssignmentIdentifier,
    Experiment,
    ExperimentResult,
    ExperimentStatus,
    Slots,
    WaitingQueueWorker
  }

  alias Magpie.Repo

  alias Ecto.Multi
  import Ecto.Query
  import Magpie.Helpers

  require Logger

  def create_experiment(experiment_params) do
    changeset_experiment = Experiment.create_changeset(%Experiment{}, experiment_params)

    changeset_experiment
    |> Repo.insert()

    # |> create_experiment_make_multi_with_insert()
    # |> Repo.transaction()
  end

  # defp create_experiment_make_multi_with_insert(changeset_experiment) do
  #   Multi.new()
  #   |> Multi.insert(:experiment, changeset_experiment)
  #   |> Multi.merge(fn %{experiment: experiment} ->
  #     # TODO: Of course we should be able to use insert_all... But this could be left as a further improvement I guess.
  #     Enum.reduce(1..experiment.num_variants, Multi.new(), fn variant, multi ->
  #       Enum.reduce(1..experiment.num_chains, multi, fn chain, multi ->
  #         Enum.reduce(1..experiment.num_generations, multi, fn generation, multi ->
  #           Enum.reduce(1..experiment.num_players, multi, fn player, multi ->
  #             params = %{
  #               experiment_id: experiment.id,
  #               variant: variant,
  #               chain: chain,
  #               generation: generation,
  #               player: player,
  #               status: 0
  #             }

  #             changeset = ExperimentStatus.changeset(%ExperimentStatus{}, params)

  #             multi
  #             |> Multi.insert(
  #               String.to_atom("experiment_status_#{chain}_#{variant}_#{generation}_#{player}"),
  #               changeset
  #             )
  #           end)
  #         end)
  #       end)
  #     end)
  #   end)
  # end

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
    |> Experiment.update_changeset(attrs)
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

  def create_experiment_result(experiment, assignment_identifier, results) do
    experiment
    |> Ecto.build_assoc(:experiment_results)
    |> ExperimentResult.changeset(%{
      "assignment_identifier" => assignment_identifier,
      "results" => results,
      "is_intermediate" => false
    })
    |> Repo.insert()
  end

  def submit_experiment(experiment_id, results) do
    with experiment when not is_nil(experiment) <- get_experiment(experiment_id),
         true <- experiment.active,
         {:ok, _} <- update_experiment_result_columns(experiment, results),
         {:ok, _} <- create_experiment_result(experiment, results) do
      :ok
    else
      nil -> {:error, :experiment_not_found}
      false -> {:error, :experiment_inactive}
      {:error, %Ecto.Changeset{} = _changeset} -> {:error, :unprocessable_entity}
      _ -> {:error, :unprocessable_entity}
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
    with [_submission | _] = experiment_submissions <-
           Repo.all(Ecto.assoc(experiment, :experiment_results)),
         {:ok, file_path} <- Briefly.create(),
         file <- File.open!(file_path, [:write, :utf8]),
         [_key | _] = keys <-
           get_keys_for_csv_download(experiment.experiment_result_columns, experiment_submissions) do
      prepare_submissions_for_csv_download(keys, experiment_submissions)
      # Enum.each because the CSV library returns a stream, with each row being an entry. We need to make the stream concrete with this step.
      |> Enum.each(&IO.write(file, &1))

      File.close(file)

      {:ok, file_path}
    else
      [] -> {:error, :no_submissions_yet}
      error -> error
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
      from(es in ExperimentStatus,
        where: es.status == :in_progress,
        where: is_nil(es.last_heartbeat) or es.last_heartbeat < ^two_minutes_ago
      )

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

  # Right, just as expected, there was indeed another workflow for "interactive" experiments
  # The confusing thing is, have we been using this endpoint for all iterative experiments all the time? I would imagine yes then.
  # OK, I'll then need to refactor the REST endpoint as well so that we support it. Or alternatively get rid of it, which I don't think we'll ever do.
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

  def submit_experiment_results(
        experiment_id,
        %AssignmentIdentifier{} = assignment_identifier,
        results
      ) do
    Repo.transaction(fn ->
      with experiment <- get_experiment!(experiment_id),
           {:ok, _experiment_result} <-
             create_experiment_result(experiment, assignment_identifier, results),
           {:ok, updated_experiment} <-
             Slots.set_slot_as_complete(experiment, assignment_identifier),
           {{:ok, %Experiment{} = _freed_experiment}, freed_count} <-
             Slots.free_slots(updated_experiment) do
        case freed_count do
          0 ->
            freed_count

          # Just call the GenServer here.
          # Or do I actually want to call the assign_slots function below?
          _ ->
            Magpie.Endpoint.broadcast!("waiting_queue:#{experiment_id}", "slot_available", %{})
            freed_count
        end
      end
    end)
  end

  def assign_slots_to_waiting_participants(freed_count) do
    # We would need to call the pop_participant function from WaitingQueueWorker
    # We get a participant id here.
    # We should then broadcast a message for the participant to join the experiment.
    # So we would actually need the actual slot identifiers here?
    # OK, fuck this. I think I know what to do now: Let's actually schedule a worker to constantly poll the queue. Architecture-wise this decouples things much more and makes it so much simpler. Let's go on then. Let's go eh. Let's go. asdfasdf.
    {:ok, participant_id} = WaitingQueueWorker.pop_participant()
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

  def report_heartbeat(assignment_identifier_str) when is_binary(assignment_identifier_str) do
    {:ok, assignment_identifier} = AssignmentIdentifier.from_string(assignment_identifier_str)

    report_heartbeat(assignment_identifier)
  end

  def report_heartbeat(%AssignmentIdentifier{} = assignment_identifier) do
    now = DateTime.utc_now()

    assignment_identifier
    |> get_experiment_status()
    |> ExperimentStatus.changeset(%{last_heartbeat: now})
    |> Repo.update!()
  end

  @doc """
  Fetch all experiment results with the given identifier (could be more than one due to multiple submissions).
  """
  def get_all_experiment_results_for_identifier(%AssignmentIdentifier{} = assignment_identifier) do
    query =
      from(er in ExperimentResult,
        where: er.experiment_id == ^assignment_identifier.experiment_id,
        where: er.variant == ^assignment_identifier.variant,
        where: er.chain == ^assignment_identifier.chain,
        where: er.generation == ^assignment_identifier.generation,
        where: er.player == ^assignment_identifier.player,
        where: er.is_intermediate == false,
        order_by: [desc: er.inserted_at]
      )

    Repo.all(query)
  end

  @doc """
  Just take the first one out of the potential list of results.
  """
  def get_one_experiment_results_for_identifier(%AssignmentIdentifier{} = assignment_identifier) do
    List.first(get_all_experiment_results_for_identifier(assignment_identifier))
  end

  def get_and_set_to_in_progress_next_available_assignment(experiment_id) do
    Repo.transaction(fn ->
      # This could be a bit slow but I hope it will still be efficient enough. The participant can wait.
      query =
        from(s in ExperimentStatus,
          where: s.experiment_id == ^experiment_id,
          where: s.status == :open,
          # Player gets incremented first and variant second, chain third, and generation last.
          order_by: [s.generation, s.chain, s.variant, s.player],
          limit: 1,
          lock: "FOR UPDATE"
        )

      # Will produce nil in the case of empty list of results.
      experiment_status = List.first(Repo.all(query))

      case experiment_status do
        nil ->
          nil

        experiment_status ->
          set_experiment_status_to_in_progress(experiment_status)
      end
    end)
  end

  defp set_experiment_status_to_in_progress(experiment_status) do
    # Mark this assignment as "in progress", i.e. allocated to this participant.
    changeset =
      experiment_status
      |> ExperimentStatus.changeset(%{status: :in_progress})

    case Repo.update(changeset) do
      {:ok, updated_experiment_status} ->
        updated_experiment_status

      {:error, _} ->
        :error
    end
  end

  # Fetch the keys from the first submission.
  defp get_keys_for_csv_download(nil, submissions) do
    with [submission | _] <- submissions,
         [trial | _] <- submission.results do
      Map.keys(trial)
    else
      _ -> :error
    end
  end

  defp get_keys_for_csv_download([], submissions) do
    with [submission | _] <- submissions,
         [trial | _] <- submission.results do
      Map.keys(trial)
    else
      _ -> :error
    end
  end

  # Get the keys from the columns already accumulated from the DB.
  defp get_keys_for_csv_download(columns, _experiment_submissions) do
    columns
  end

  defp prepare_submissions_for_csv_download(:error, _submissions) do
    []
  end

  # Writes the submissions to a CSV file.
  # Note that we have a validation in schemas to ensure that each entry in `results` must have the same set of keys. So the following code take take that as an assumption.
  defp prepare_submissions_for_csv_download(keys, submissions) do
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
      # This is processing done when one of fields is an array. Though this type of submission should be discouraged.
      |> Enum.map(fn k -> format_value(Map.get(trial, k, "")) end)
    end)
  end

  defp update_experiment_result_columns(experiment, results) do
    # previously_accumulated_columns <- experiment.
    with [trial | _] <- results,
         keys <- Map.keys(trial),
         previously_accumulated_columns <-
           Map.get(experiment, :experiment_result_columns) || [],
         new_experiment_result_columns <- merge_columns(keys, previously_accumulated_columns) do
      update_experiment(experiment, %{experiment_result_columns: new_experiment_result_columns})
    else
      [] -> {:error, :unprocessable_entity}
      error -> error
    end
  end

  defp merge_columns(keys, previously_accumulated_columns) do
    merged_columns = MapSet.union(MapSet.new(keys), MapSet.new(previously_accumulated_columns))
    MapSet.to_list(merged_columns)
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
