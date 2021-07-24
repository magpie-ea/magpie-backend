defmodule Magpie.CustomRecordHelper do
  @moduledoc """
  Stores the helper functions for custom records.
  """
  defp format_record(record, keys) do
    # Essentially this is just reordering.
    Enum.map(record, fn entry ->
      # For each entry, use the order specified by keys
      keys
      |> Enum.map(fn k -> entry[k] end)
      |> Enum.map(fn v -> Magpie.Experiments.format_value(v) end)
    end)
  end

  def write_record(file, record) do
    # First the headers for the csv file will be generated
    [entry | _] = record
    keys = Map.keys(entry)
    # The first element in the `outputs` list of lists will be the keys, i.e. headers
    outputs = [keys]

    # For each entry, concatenate it to the `outputs` list.
    outputs = outputs ++ format_record(record, keys)
    outputs |> CSV.encode() |> Enum.each(&IO.write(file, &1))
  end

  def convert_uploaded_data(upload) do
    case upload.content_type do
      "application/json" ->
        data =
          upload.path
          |> File.read!()
          |> Jason.decode!()

        {:ok, data}

      "text/csv" ->
        data =
          upload.path
          |> File.stream!()
          # TODO: Should probably use the gentler `decode` version and manually pass down the errors. Or maybe one should simply separate the conversion for JSON and CSV into two separate functions.
          |> CSV.decode!(headers: true)
          # Because it returns a stream, we just simply make the results concrete here.
          |> Enum.take_every(1)

        {:ok, data}

      _ ->
        :error
    end
  end
end
