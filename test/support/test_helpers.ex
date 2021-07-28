defmodule Magpie.TestHelpers do
  @moduledoc """
  Helper functions for tests
  """

  @complex_experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    dynamic_retrieval_keys: ["key1", "key2", "key3"],
    is_dynamic: true,
    num_variants: 2,
    num_chains: 5,
    num_generations: 3
  }

  @experiment_attrs %{
    name: "some name",
    author: "some author",
    description: "some description",
    active: true,
    is_dynamic: false
  }

  @custom_record_attrs %{
    name: "some name",
    record: [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22}]
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

    {:ok, %{experiment: experiment}} = Magpie.Experiments.create_experiment(changes)
    experiment
  end

  def insert_experiment(attrs \\ %{}) do
    changes =
      Map.merge(
        @experiment_attrs,
        attrs
      )

    {:ok, %{experiment: experiment}} = Magpie.Experiments.create_experiment(changes)
    experiment
  end

  def insert_custom_record(attrs \\ %{}) do
    changes =
      Map.merge(
        @custom_record_attrs,
        attrs
      )

    changeset =
      Magpie.CustomRecords.CustomRecord.changeset(%Magpie.CustomRecords.CustomRecord{}, changes)

    {:ok, custom_record} = Magpie.Repo.insert(changeset)
    custom_record
  end

  def insert_experiment_result(attrs \\ %{}) do
    changes =
      Map.merge(
        @experiment_result_attrs,
        attrs
      )

    %Magpie.Experiments.ExperimentResult{}
    |> Magpie.Experiments.ExperimentResult.changeset(changes)
    |> Magpie.Repo.insert!()
  end

  # Functions to expose those attributes to actual test modules.
  def get_experiment_attrs() do
    @experiment_attrs
  end

  def get_complex_experiment_attrs() do
    @complex_experiment_attrs
  end
end
