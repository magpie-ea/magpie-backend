defmodule BABE.ExperimentHelper do
  @moduledoc """
  Stores the helper functions which help to store and retrieve the experiments.
  """

  @doc """
  Checks that the submitted results are a JSON array of objects and that each object in the array contains the same set of keys.
  Or maybe let me not check the "same keys" requirement first. We can do it later, or just fill in nil when some keys are not present.
  """
  def valid_results(results) do
    case results do
      # Sometimes empty results come in for no reason.
      [] -> false
      # TODO: A more foolproof way might be to use a JSON schema library to check every item for being identical.
      [hd | _] when is_map(hd) -> true
      _ -> false
    end
  end

  # But then, of course, the caveat is that for each set of *results*, we should only write the column headers once.
  # !!Assumption!!: Each `ExperimentResult` is a JSON array, which contains objects with an identical set keys.
  # Could use some JSON schema library though now we don't do it yet.
  def write_submissions(file, submissions) do
    # There were some malformed data (empty results field) for unknown reasons. I'll just use some primitive mechanisms to try to deal with them for now.
    # Also, from now on such results will not be accepted in the future either.
    submissions =
      Enum.filter(submissions, fn submission ->
        valid_results(submission.results)
      end)

    try do
      # Here the headers for the csv file will be recorded
      [submission | _] = submissions
      [trial | _] = submission.results
      keys = Map.keys(trial)
      # We need to prepend a column which contains uid in the output
      keys = ["submission_id" | keys]

      # The first element in the `outputs` list of lists will be the keys, i.e. headers
      outputs = [keys]
      # IO.inspect outputs = outputs ++ keys, label: "outputs"

      # For each experimentresult, get the results and concatenate it to the `outputs` list.
      outputs =
        outputs ++
          List.foldl(submissions, [], fn submission, acc ->
            acc ++ format_submission(submission, keys)
          end)

      outputs |> CSV.encode() |> Enum.each(&IO.write(file, &1))
      {:ok}
    rescue
      # Usually it's a MatchError
      MatchError -> {:error}
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
      |> Enum.map(fn v ->
        if is_list(v) do
          Enum.join(v, "|")
        else
          v
        end
      end)
    end)
  end
end
