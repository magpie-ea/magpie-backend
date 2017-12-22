defmodule ProComPrag.ExperimentHelper do
  @moduledoc """
  Stores the helper functions which help to store and retrieve the experiments.
  """
  def decompose_experiment(experiment) do
    results = experiment.results
    results_without_trials = Map.delete(results, "trials")

    # The point is just to get rid of the intermediate numberings added when the data was saved to the DB.
    trials = results["trials"]

    # I'm not sure if we need the extra metadata outside of the results. But I guess we can include it at the end of each row anyways. The `time_created` column could be useful.
    # The __meta__ I'm removing here is the "true" meta info from Elixir... So it's not needed in the final output.
    meta_info = Map.drop(experiment, [:results, :__meta__, :id, :__struct__])

    %{results_without_trials: results_without_trials, trials: trials, meta_info: meta_info}
  end

  # Note that the default way Amazon MTurk writes an experiment is to simply flatten the structure, and then take each key as a column header.
  # We might be able to do something similar here.
  # But then, of course, the caveat is that for each set of *experiments*, we should only write the column headers once.
  # !!Assumption!!: The content structure of the JSONs for each *set of experiments* should be exactly the same, of course.
  def write_experiments(file, experiments) do
    # Here the headers for the csv file will be written
    [experiment | _] = experiments
    decomposed_experiment = decompose_experiment(experiment)

    # The point of processing trials separately is to get rid of the intermediate numberings added when the data was saved to the DB, since we want each trial to be presented as an individual row eventually.
    # Assumption: Each trial should have the same keys recorded.
    trial = decomposed_experiment[:trials]["0"]
    trial_keys = trial
                # Actually I might not even need this prefixing. Could ask Michael for input on this.
                # |> Enum.map(fn(k) -> "trial." <> k end)
                 |> Enum.map(fn({k, _v}) -> k end)

    # Record the flattened keys, as is done originally by MTurk.
    other_info_keys = decomposed_experiment[:results_without_trials]\
           |> Iteraptor.to_flatmap\
           |> Enum.map(fn({k, _v}) -> k end)


    # I'm not sure if we need the extra metadata outside of the results. Maybe for completeness's sake I'll still write them out first. This may also include information such as participant_id etc.
    meta_info_keys = decomposed_experiment[:meta_info]\
                     |> Enum.map(fn({k, _v}) -> k end)

    # You cannot pipe something as the second argument... A temporary variable might make it more readable

    t = trial_keys |> Enum.join("\t")
    o = other_info_keys |> Enum.join("\t")
    m = meta_info_keys |> Enum.join("\t")

    IO.write(file, t)
    IO.write(file, "\t")
    IO.write(file, o)
    IO.write(file, "\t")
    IO.write(file, m)

    # Write the individual experiment results
    IO.write(file, "\n")
    Enum.each(experiments, &write_experiment(file, &1))
  end

  def write_experiment(file, experiment) do
    decomposed_experiment = decompose_experiment(experiment)

    # TODO: I can probably refactor the code a bit further (the only difference with the code above is that the values are extracted instead of the keys). But let me do it later then.
    other_info = decomposed_experiment[:results_without_trials]\
           |> Iteraptor.to_flatmap\
           |> Enum.map(fn({_k, v}) -> v end)
           |> Enum.map(fn(v) ->
      if is_list(v) do Enum.join(v, "|") else v end
    end)

    meta_info = decomposed_experiment[:meta_info]\
                |> Enum.map(fn({_k, v}) -> v end)
                |> Enum.map(fn(v) ->
      if is_list(v) do Enum.join(v, "|") else v end
    end)

    # New lines in the user responses are wrecking havoc in the final csv file... I'll replace them with a literal \n. Not sure if other special characters will also need to be taken care of though.
    o = other_info |> Enum.join("\t") |> String.replace("\n", "\\n")
    m = meta_info |> Enum.join("\t") |> String.replace("\n", "\\n")

    for {_k, trial} <- decomposed_experiment[:trials] do
      trial_info = trial\
                   |> Enum.map(fn({_k, v}) -> v end)\
                   |> Enum.map(fn(v) ->\
                     if is_list(v) do Enum.join(v, "|") else v end\
                    end)

      t = trial_info |> Enum.join("\t") |> String.replace("\n", "\\n")

      IO.write(file, t)
      IO.write(file, "\t")
      IO.write(file, o)
      IO.write(file, "\t")
      IO.write(file, m)
      IO.write(file, "\n")

    end
  end
end
