defmodule Magpie.Helpers do
  @moduledoc """
  Helper functions for the contexts
  """

  # This special processing has always been there and let's keep it this way.
  def format_value(value) when is_list(value) do
    Enum.join(value, "|")
  end

  def format_value(value) do
    case String.Chars.impl_for(value) do
      # e.g. maps. Then we just return it as it is.
      nil ->
        Kernel.inspect(value)

      _ ->
        to_string(value)
    end
  end

  def check_record(atom, record) do
    case {Enum.empty?(record), contain_the_same_keys?(record)} do
      # First check if the record are empty
      {true, _} -> [{atom, "cannot be empty"}]
      # Then check whether each map in the array has the same keys
      {_, false} -> [{atom, "every entry must have the same set of keys"}]
      _ -> []
    end
  end

  defp contain_the_same_keys?(record) do
    all_keys =
      record
      |> Enum.map(fn entry -> Enum.sort(Map.keys(entry)) end)

    # List.first instead of hd because it could be an empty list
    first_keys = List.first(all_keys)

    Enum.reduce(all_keys, true, fn keys, acc ->
      acc and
        keys == first_keys
    end)
  end
end
