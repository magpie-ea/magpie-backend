defmodule Magpie.Experiments.CustomRecord do
  @moduledoc """
  A custom record is a flexible data record (map) which is intended to be retrieved as JSON by experiments on the fly, to provide support for dynamic experiments. There are multiple ways to create/modify it:
  - Manual upload of a CSV file
  - Manual upload of a JSON file
  - Generation from a set of experiment results via some rules.
  """
  use MagpieWeb, :model

  import Magpie.ModelHelper

  schema "custom_records" do
    field(:name, :string)
    field(:record, {:array, :map})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(custom_record, attrs \\ %{}) do
    custom_record
    |> cast(attrs, [:name, :record])
    |> validate_required([:name, :record])
    |> validate_change(:record, &check_record(&1, &2))
  end
end
