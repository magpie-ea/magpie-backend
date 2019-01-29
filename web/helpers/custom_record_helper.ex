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

  def convert_uploaded_data(upload) do
    case upload.content_type do
      "application/json" ->
        upload.path
        |> File.read!()
        |> Poison.decode!()

      "text/csv" ->
        upload.path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        # We shouldn't need to manually verify that the rows are valid. The decode! should do it for us
        # |> Stream.filter(fn({k, v}) -> k == :ok end)
        # |> Stream.map(fn({k, v}) -> v end)
        # Because it returns a stream, we just simply make the results concrete here.
        |> Enum.take_every(1)

      _ ->
        nil
    end
  end
end
