defmodule Magpie.ExperimentTest do
  @moduledoc """
  Tests for the Experiment model
  """
  use Magpie.ModelCase

  alias Magpie.Experiments.Experiment
  alias Magpie.Repo

  @non_complex_experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    dynamic_retrieval_keys: ["a", "b", "c"],
    is_dynamic: false
  }

  @complex_experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    dynamic_retrieval_keys: ["a", "b", "c"],
    is_dynamic: true,
    num_variants: 2,
    num_chains: 5,
    num_generations: 3
  }

  @innon_complex_experiment_attrs %{
    name: nil,
    author: nil,
    active: nil,
    is_dynamic: nil
  }

  test "changeset with valid attributes" do
    changeset = Experiment.changeset(%Experiment{}, @non_complex_experiment_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Experiment.changeset(%Experiment{}, @innon_complex_experiment_attrs)
    refute changeset.valid?
  end

  test "name is required" do
    changeset =
      Experiment.changeset(%Experiment{}, Map.delete(@non_complex_experiment_attrs, :name))

    refute changeset.valid?
  end

  test "author is required" do
    changeset =
      Experiment.changeset(%Experiment{}, Map.delete(@non_complex_experiment_attrs, :author))

    refute changeset.valid?
  end

  test "active is not required and defaults to `true`" do
    changeset =
      Experiment.changeset(%Experiment{}, Map.delete(@non_complex_experiment_attrs, :active))

    {:ok, experiment} = Repo.insert(changeset)
    assert experiment.active == true
  end

  test "is_dynamic is not required and defaults to `false`" do
    changeset =
      Experiment.changeset(%Experiment{}, Map.delete(@non_complex_experiment_attrs, :is_dynamic))

    {:ok, experiment} = Repo.insert(changeset)
    assert experiment.is_dynamic == false
  end

  test "description is not required" do
    changeset =
      Experiment.changeset(%Experiment{}, Map.delete(@non_complex_experiment_attrs, :description))

    assert changeset.valid?
  end

  test "dynamic_retrieval_keys is not required" do
    changeset =
      Experiment.changeset(
        %Experiment{},
        Map.delete(@non_complex_experiment_attrs, :dynamic_retrieval_keys)
      )

    assert changeset.valid?
  end

  describe "complex experiments" do
    test "complex experiments must have num_variants" do
      changeset =
        Experiment.changeset(%Experiment{}, Map.delete(@complex_experiment_attrs, :num_variants))

      refute changeset.valid?
    end

    test "complex experiments must have num_chains" do
      changeset =
        Experiment.changeset(%Experiment{}, Map.delete(@complex_experiment_attrs, :num_chains))

      refute changeset.valid?
    end

    test "complex experiments must have num_generations" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.delete(@complex_experiment_attrs, :num_generations)
        )

      refute changeset.valid?
    end

    test "num_variants must be greater than 0" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@complex_experiment_attrs, :num_variants, 0)
        )

      assert {:num_variants,
              {"must be greater than %{number}",
               [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
    end

    test "num_chains must be greater than 0" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@complex_experiment_attrs, :num_chains, 0)
        )

      assert {:num_chains,
              {"must be greater than %{number}",
               [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
    end

    test "num_generations must be greater than 0" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@complex_experiment_attrs, :num_generations, 0)
        )

      assert {:num_generations,
              {"must be greater than %{number}",
               [validation: :number, kind: :greater_than, number: 0]}} in changeset.errors
    end

    test "non-complex experiments cannot have num_variants" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@non_complex_experiment_attrs, :num_variants, 2)
        )

      refute changeset.valid?
    end

    test "non-complex experiments cannot have num_chains" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@non_complex_experiment_attrs, :num_chains, 2)
        )

      refute changeset.valid?
    end

    test "non-complex experiments cannot have num_generations" do
      changeset =
        Experiment.changeset(
          %Experiment{},
          Map.put(@non_complex_experiment_attrs, :num_generations, 2)
        )

      refute changeset.valid?
    end
  end
end
