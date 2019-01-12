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

  def insert_complex_experiment(attrs \\ %{}) do
    changes =
      Map.merge(
        @complex_experiment_attrs,
        attrs
      )

    %BABE.Experiment{}
    |> BABE.Experiment.changeset(changes)
    |> BABE.Repo.insert!()
  end

  def insert_experiment(attrs \\ %{}) do
    changes =
      Map.merge(
        @experiment_attrs,
        attrs
      )

    %BABE.Experiment{}
    |> BABE.Experiment.changeset(changes)
    |> BABE.Repo.insert!()
  end
end
