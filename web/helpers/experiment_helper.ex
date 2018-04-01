defmodule ProComPrag.ExperimentHelper do
  @moduledoc """
  Stores the helper functions which help to store and retrieve the experiments.
  """
  def decompose_experiment(experiment) do
    # `experiment` is a map, representing a row from the database.
    results = experiment.results
    results_without_trials = Map.delete(results, "trials")

    # The purpose is just to get rid of the intermediate numberings added to the trials when the data was saved to the DB.
    trials = results["trials"]

    # I'm not sure if we need the extra metadata outside of the results. But I guess we can include it at the end of each row anyways. The `time_created` column could be useful.
    # The __meta__ I'm removing here is the "true" meta info from Elixir... So it's not needed in the final output.
    meta_info = Map.drop(experiment, [:results, :__meta__, :__struct__])
                # Had to perform Enum.map step since there are two fields (insertion time and update time) which are ~N sigils. These two are not really necessary. May well just drop them as well in the future?
                |> Enum.map(fn({k, v}) -> {k, to_string(v)} end)

    %{results_without_trials: results_without_trials, trials: trials, meta_info: meta_info}
  end

  # Note that the default way Amazon MTurk writes an experiment is to simply flatten the structure, and then take each key as a column header.
  # We might be able to do something similar here.
  # But then, of course, the caveat is that for each set of *experiments*, we should only write the column headers once.
  # !!Assumption!!: The content structure of the JSONs for each *set of experiments* should be exactly the same, of course.
  def write_experiments(file, experiments) do
    # Here the headers for the csv file will be recorded
    [experiment | _] = experiments
    keys = get_keys(experiment)
    # The first element in the `outputs` list will be the keys, i.e. headers
    outputs = [keys]

    # For each experiment, get the results and concatenate it to the `outputs` list.
    outputs = outputs ++ List.foldl(experiments, [], fn(exp, acc) -> acc ++ return_results_from_experiment(exp) end)
    outputs |> CSV.encode |> Enum.each(&IO.write(file, &1))
  end

  def get_keys(experiment) do
    decomposed_experiment = decompose_experiment(experiment)

    # The point of processing trials separately is to get rid of the intermediate numberings added when the data was saved to the DB, since we want each trial to be presented as an individual row eventually.
    # Assumption: Each trial should have the same keys recorded.
    trial = decomposed_experiment[:trials]["0"]
    trial_keys = trial
                 # Actually I might not even need this prefixing. Could ask Michael for input on this.
                 # |> Enum.map(fn(k) -> "trial." <> k end)
                 |> Enum.map(fn({k, _v}) -> k end)

    # Record the flattened keys, as is done originally by MTurk.
    other_info_keys = decomposed_experiment[:results_without_trials]
                      |> Iteraptor.to_flatmap
                      |> Enum.map(fn({k, _v}) -> k end)

    # I'm not sure if we need the extra metadata outside of the results. Maybe for completeness's sake I'll still write them out first. This may also include information such as participant_id etc.
    meta_info_keys = decomposed_experiment[:meta_info]
                     |> Enum.map(fn({k, _v}) -> k end)

    # OK, now I have all the keys. Let me just put them into one list as the first entry.
    keys = meta_info_keys ++ trial_keys ++ other_info_keys
    keys
  end

  # I'm not sure if I'll manually convert the list or whether the library already handles it. In any case this will be a bad habit?
  def return_results_from_experiment(experiment) do
    decomposed_experiment = decompose_experiment(experiment)

    # TODO: I can probably refactor the code a bit further (the only difference with the get_keys function is that the values are extracted instead of the keys). But let me do it later then.
    other_info = decomposed_experiment[:results_without_trials]
                 |> Iteraptor.to_flatmap
                 |> Enum.map(fn({_k, v}) -> v end)
                 |> Enum.map(fn(v) ->
      if is_list(v) do Enum.join(v, "|") else v end
    end)

    meta_info = decomposed_experiment[:meta_info]
                |> Enum.map(fn({_k, v}) -> v end)
                |> Enum.map(fn(v) ->
      if is_list(v) do Enum.join(v, "|") else v end
    end)

    trials = Enum.map(decomposed_experiment[:trials], fn({_k, trial}) ->
      trial_info = trial
                   |> Enum.map(fn({_k, v}) -> v end)
                   |> Enum.map(fn(v) ->
        if is_list(v) do Enum.join(v, "|") else v end
      end)

      # Here we combine every information into one row.
      trial = meta_info ++ trial_info ++ other_info
      trial
    end)

    results = List.foldl(trials, [], fn(trial, results) -> results ++ [trial] end)
    results
  end
end
