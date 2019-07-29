defmodule Magpie.ExperimentResultTest do
  @moduledoc """
  Tests for the ExperimentResult model
  """
  use Magpie.ModelCase

  alias Magpie.ExperimentResult

  @valid_attrs %{
    experiment_id: 1,
    variant: 1,
    chain: 2,
    realization: 3,
    results: [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22}]
  }

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ExperimentResult.changeset(%ExperimentResult{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ExperimentResult.changeset(%ExperimentResult{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "experiment_id is required" do
    changeset =
      ExperimentResult.changeset(%ExperimentResult{}, Map.delete(@valid_attrs, :experiment_id))

    refute changeset.valid?
  end

  test "variant is not required" do
    changeset =
      ExperimentResult.changeset(%ExperimentResult{}, Map.delete(@valid_attrs, :variant))

    assert changeset.valid?
  end

  test "chain is not required" do
    changeset = ExperimentResult.changeset(%ExperimentResult{}, Map.delete(@valid_attrs, :chain))

    assert changeset.valid?
  end

  test "realization is not required" do
    changeset =
      ExperimentResult.changeset(%ExperimentResult{}, Map.delete(@valid_attrs, :realization))

    assert changeset.valid?
  end

  test "results cannot be empty" do
    changeset =
      ExperimentResult.changeset(%ExperimentResult{}, Map.put(@valid_attrs, :results, []))

    assert {:results, {"cannot be empty", []}} in changeset.errors
  end

  test "every entry in `results` must have the same set of keys" do
    changeset =
      ExperimentResult.changeset(
        %ExperimentResult{},
        Map.put(@valid_attrs, :results, [
          %{"a" => 1, "b" => 2},
          %{"a" => 11}
          # %{"a" => 11, "b" => 22, "c" => 33}
        ])
      )

    assert {:results, {"every entry must have the same set of keys", []}} in changeset.errors
  end
end
