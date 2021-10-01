defmodule Magpie.ExperimentStatusTest do
  @moduledoc """
  Tests for the ExperimentStatus model
  """
  use Magpie.ModelCase

  alias Magpie.Experiments.ExperimentStatus

  @valid_attrs %{
    experiment_id: 1,
    variant: 1,
    chain: 2,
    generation: 3,
    player: 1,
    status: :completed
  }

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ExperimentStatus.changeset(%ExperimentStatus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ExperimentStatus.changeset(%ExperimentStatus{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "experiment_id is required" do
    changeset =
      ExperimentStatus.changeset(%ExperimentStatus{}, Map.delete(@valid_attrs, :experiment_id))

    refute changeset.valid?
  end

  test "variant is required" do
    changeset =
      ExperimentStatus.changeset(%ExperimentStatus{}, Map.delete(@valid_attrs, :variant))

    refute changeset.valid?
  end

  test "chain is required" do
    changeset = ExperimentStatus.changeset(%ExperimentStatus{}, Map.delete(@valid_attrs, :chain))

    refute changeset.valid?
  end

  test "generation is required" do
    changeset =
      ExperimentStatus.changeset(%ExperimentStatus{}, Map.delete(@valid_attrs, :generation))

    refute changeset.valid?
  end

  test "variant must be greater than 0" do
    changeset =
      ExperimentStatus.changeset(
        %ExperimentStatus{},
        Map.put(@valid_attrs, :variant, 0)
      )

    assert {:variant,
            {"must be greater than %{number}",
             [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
  end

  test "chain must be greater than 0" do
    changeset =
      ExperimentStatus.changeset(
        %ExperimentStatus{},
        Map.put(@valid_attrs, :chain, 0)
      )

    assert {:chain,
            {"must be greater than %{number}",
             [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
  end

  test "generation must be greater than 0" do
    changeset =
      ExperimentStatus.changeset(
        %ExperimentStatus{},
        Map.put(@valid_attrs, :generation, 0)
      )

    assert {:generation,
            {"must be greater than %{number}",
             [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
  end
end
