defmodule BABE.CustomRecordHelper do
  @moduledoc """
  Stores the helper functions for custom records.
  """
  defp format_record(record, keys) do
    # Essentially this is just reordering.
    Enum.map(record, fn entry ->
      # For each entry, use the order specified by keys
      keys
      |> Enum.map(fn k -> entry[k] end)
    end)
  end

  def write_record(file, record) do
    # First the headers for the csv file will be generated
    [entry | _] = record
    keys = Map.keys(entry)
    # The first element in the `outputs` list of lists will be the keys, i.e. headers
    outputs = [keys]
    # IO.inspect outputs = outputs ++ keys, label: "outputs"

    # For each entry, concatenate it to the `outputs` list.
    outputs = outputs ++ format_record(record, keys)
    outputs |> CSV.encode() |> Enum.each(&IO.write(file, &1))
  end
end
