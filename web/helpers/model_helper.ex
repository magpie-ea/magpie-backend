defmodule BABE.ModelHelper do
  @moduledoc """
  Helper functions for models
  """
  def check_record(atom, record) do
    case {Enum.empty?(record), contain_the_same_keys?(record)} do
      # First check if the record are empty
      {true, _} -> [{atom, "cannot be empty"}]
      # Then check whether each map in the array has the same keys
      {_, false} -> [{atom, "every entry must have the same set of keys"}]
      _ -> []
    end
  end

  def contain_the_same_keys?(record) do
    all_keys =
      record
      |> Enum.map(fn entry -> Enum.sort(Map.keys(entry)) end)

    # List.first instead of hd because it could be an empty list
    first_keys = List.first(all_keys)

    Enum.reduce(all_keys, first_keys, fn keys, problem_free ->
      problem_free && keys == first_keys
    end)
  end
end
