defmodule Magpie.CustomRecordTest do
  @moduledoc """
  Tests for the CustomRecord model
  """
  use Magpie.ModelCase

  alias Magpie.CustomRecord

  @valid_attrs %{
    name: "some name",
    record: [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22}]
  }

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = CustomRecord.changeset(%CustomRecord{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CustomRecord.changeset(%CustomRecord{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "name is required" do
    changeset = CustomRecord.changeset(%CustomRecord{}, Map.delete(@valid_attrs, :name))
    refute changeset.valid?
  end

  test "record is required" do
    changeset = CustomRecord.changeset(%CustomRecord{}, Map.delete(@valid_attrs, :record))
    refute changeset.valid?
  end

  test "record cannot be empty" do
    changeset = CustomRecord.changeset(%CustomRecord{}, Map.put(@valid_attrs, :record, []))

    assert {:record, {"cannot be empty", []}} in changeset.errors
  end

  test "every entry in `record` must have the same set of keys" do
    changeset =
      CustomRecord.changeset(
        %CustomRecord{},
        Map.put(@valid_attrs, :record, [
          %{"a" => 1, "b" => 2},
          %{"a" => 11}
          # %{"a" => 11, "b" => 22, "c" => 33}
        ])
      )

    assert {:record, {"every entry must have the same set of keys", []}} in changeset.errors
  end
end
