defmodule BABE.TestHelpers do
  @moduledoc """
  Helper functions for tests
  """

  @complex_experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    dynamic_retrieval_keys: ["key1", "key2", "key3"],
    is_complex: true,
    num_variants: 2,
    num_chains: 5,
    num_realizations: 3
  }

  @experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    is_complex: false
  }

  @results_simple_experiment [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22}]

  @experiment_result_attrs %{
    "results" => @results_simple_experiment
  }

  def insert_complex_experiment(attrs \\ %{}) do
    changes =
      Map.merge(
        @complex_experiment_attrs,
        attrs
      )

    {:ok, %{experiment: experiment}} = BABE.ExperimentHelper.create_experiment(changes)
    experiment
  end

  def insert_experiment(attrs \\ %{}) do
    changes =
      Map.merge(
        @experiment_attrs,
        attrs
      )

    {:ok, %{experiment: experiment}} = BABE.ExperimentHelper.create_experiment(changes)
    experiment
  end

  def insert_experiment_result(attrs \\ %{}) do
    changes =
      Map.merge(
        @experiment_result_attrs,
        attrs
      )

    %BABE.ExperimentResult{}
    |> BABE.ExperimentResult.changeset(changes)
    |> BABE.Repo.insert!()
  end

  # Functions to expose those attributes to actual test modules.
  def get_experiment_attrs() do
    @experiment_attrs
  end

  def get_complex_experiment_attrs() do
    @complex_experiment_attrs
  end
end
