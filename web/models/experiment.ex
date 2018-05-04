defmodule ProComPrag.Experiment do
  @moduledoc """
  An Experiment corresponds to an experiment that the author plans to run. They can decide whether to deactivate the experiment so that no new submissions will be accepted.
  """
  use ProComPrag.Web, :model

  schema "experiments" do
    field :experiment_id, :string
    field :author, :string
    field :description, :string
    field :active, :boolean, default: false
    field :maximum_submissions, :integer
    field :current_submissions, :integer, default: 0, null: false

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:experiment_id, :author, :description, :active, :maximum_submissions])
    |> validate_required([:experiment_id, :author, :active])
    |> unique_constraint(:experiment_id, name: :experiment_index)
  end
end
