defmodule ProComPrag.ExperimentHelper do
  @moduledoc """
  Stores the helper functions which help to store and retrieve the experiments.
  """
  # Note that the default way Amazon MTurk writes an experiment is to simply flatten the structure, and then take each key as a column header.
  # We might be able to do something similar here.
  # But then, of course, the caveat is that for each set of *experiments*, we should only write the column headers once.
  # !!Assumption!!: The content structure of the JSONs for each *set of experiments* should be exactly the same, of course.
  def write_experiments(file, experiments) do
    # Here the headers for the csv file will be recorded
    [experiment | _] = experiments
    keys = get_keys(experiment)
    # The first element in the `outputs` list will be the keys, i.e. headers
    outputs = [keys[:meta_info_keys] ++ keys[:trial_keys] ++ keys[:other_info_keys]]

    # For each experiment, get the results and concatenate it to the `outputs` list.
    outputs = outputs ++ List.foldl(experiments, [], fn(exp, acc) -> acc ++ return_results_from_experiment(exp, keys) end)
    outputs |> CSV.encode |> Enum.each(&IO.write(file, &1))
  end

  defp decompose_experiment(experiment) do
    # `experiment` is a map, representing a row from the database.
    # `results` is the entire JSON data submitted by the frontend.
    results = experiment.results
    results_without_trials = results
                             # Also need to drop trial_keys_order, since we obviously don't need to print it out.
                             |> Map.drop(["trials", "trial_keys_order"])
                              # Record the flattened keys, as is done originally by MTurk.
                             |> Iteraptor.to_flatmap

    # If it's old data, we want to convert them first. If it's new data, it should have already been converted when
    # being inserted, meaning we can use it as it is.
    trials = if is_list(results["trials"]) do
      results["trials"]
    else
      convert_trials(results["trials"])
    end

    trial_keys_order =
    if Map.has_key?(results, "trial_keys_order") do
      results["trial_keys_order"]
    else
      nil
    end

    # I'm not sure if we need the extra metadata outside of the results. But I guess we can include it at the end of each row anyways. The `time_created` column could be useful.
    # The __meta__ I'm removing here is the "true" meta info from Elixir... So it's not needed in the final output.
    meta_info = experiment
                |> Map.drop([:results, :__meta__, :__struct__])
                # Had to perform Enum.map step since there are two fields (insertion time and update time) which are ~N sigils. These two are not really necessary. May well just drop them as well in the future?
                |> Enum.map(fn({k, v}) -> {k, to_string(v)} end)

    # These keys are atoms by default, not strings
    %{results_without_trials: results_without_trials, trials: trials, meta_info: meta_info, trial_keys_order: trial_keys_order}
  end

  defp get_keys(experiment) do
    decomposed_experiment = decompose_experiment(experiment)

    # The point of processing trials separately is to get rid of the intermediate numberings added when the data was saved to the DB, since we want each trial to be presented as an individual row eventually.
    # Assumption: Each trial should have the same keys recorded.
    trial = Kernel.hd decomposed_experiment[:trials]

    # If the user didn't supply the desired order then just proceed like the other two set of keys. Otherwise use the supplied order instead.
    trial_keys = case decomposed_experiment[:trial_keys_order] do
      nil ->
        # Actually I might not even need this prefixing. Could ask Michael for input on this.
        # |> Enum.map(fn({k, _v}) -> "trial." <> k end)
        trial
        |> Enum.map(fn({k, _v}) -> k end)
      # This was originally a JS array. So it corresponds to an Elixir list... Good to know.
      order -> order
    end

    other_info_keys = decomposed_experiment[:results_without_trials]
                      |> Enum.map(fn({k, _v}) -> k end)

    meta_info_keys = decomposed_experiment[:meta_info]
                     |> Enum.map(fn({k, _v}) -> k end)

    # Now the keys are returned as a map to be used for return_results_from_experiment.
    # They themselves are ordered lists.
    keys = %{meta_info_keys: meta_info_keys, trial_keys: trial_keys, other_info_keys: other_info_keys}
    keys
  end

  # I'm not sure if I'll manually convert the list or whether the library already handles it. In any case this will be a bad habit?
  defp return_results_from_experiment(experiment, keys) do
    decomposed_experiment = decompose_experiment(experiment)

    other_info = keys[:other_info_keys]
                 |> Enum.map(fn(k) -> decomposed_experiment[:results_without_trials][k] end)
                 |> Enum.map(fn(v) ->
                                   if is_list(v) do Enum.join(v, "|") else v end
                    end)

    meta_info = keys[:meta_info_keys]
                 |> Enum.map(fn(k) -> decomposed_experiment[:meta_info][k] end)
                 |> Enum.map(fn(v) ->
                                    if is_list(v) do Enum.join(v, "|") else v end
                    end)

    # Go through all the trials
    trials = Enum.map(decomposed_experiment[:trials], fn(trial) ->
      # For each trial, use the order specified by trial_keys
      trial_info = keys[:trial_keys]
                   |> Enum.map(fn(k) -> trial[k] end)
                   |> Enum.map(fn(v) ->
                                      if is_list(v) do Enum.join(v, "|") else v end
                      end)

      # Here we combine every information into one row.
      trial = meta_info ++ trial_info ++ other_info
      trial
    end)

    # Here we fold every row together into a huge list.
    results = List.foldl(trials, [], fn(trial, results) -> results ++ [trial] end)
    results
  end

  # The trials (JSON array of objects) by default are somehow converted to maps. I need to get them back to lists with correct orders.
  def convert_trials(trials) do
    case trials do
      trials -> trials
                |> Enum.map(fn ({k, v}) -> {Integer.parse(k), v} end)
                |> Enum.to_list
                |> Enum.sort(fn ({key1, value1}, {key2, value2}) -> key1 < key2 end)
                |> Enum.map(fn ({k, v}) -> v end)
    end
  end


end
