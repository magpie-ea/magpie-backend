defmodule ProComPrag.Experiment do
  @moduledoc false

  use ProComPrag.Web, :model

  schema "experiments" do
    # This is a map, representing the whole JSON object received when the experiment was first submitted.
    # Maybe the name `data` would be more appropriate. But anyways. Don't want to have troubles with migrations so let's just keep it for now
    # The map type will already be JSONB in Postgres by default. It will be simply TEXT in other DBs.
    field :results, :map
    # Not to be confused with the `id` used by the DB to index entries, thus the prefix.
    field :experiment_id, :string
    field :author, :string
    # Note that the type :text is actually used for Postgres (specified in the migration file). It may not be valid for other databases. The description is potentially longer than varchar(255) limited by the default :string.
    field :description, :string
    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    # `cast/3` ensures that only the allowed parameters are let through, and that the input is safe.
    |> cast(params, [:results, :experiment_id, :author, :description])
    # Validate the required parameters are all there. In our case all parameters are required.
    |> validate_required([:results, :experiment_id, :author, :description])
    |> validate_trials_exists()
  end

  def construct_experiment_query(experiment_id, author) do
    from e in "experiments",
    where: e.experiment_id == ^experiment_id,
    where: e.author == ^author
  end

  # Verify that the trials key exists in the submitted JSON.
  # I should have made it a DB field from the very beginning... Now that the system is already deployed, it would be
  # too much of a hassle to migrate the existing data. So let's just do this instead to ensure backwards
  # compatability. Fundamentally there isn't that much of a difference.
  defp validate_trials_exists(changeset) do
    results = get_field(changeset, :results)
    if Map.has_key?(results, "trials") do
      changeset
    else
      add_error(changeset, :map_field, "Missing trials key")
    end
  end
end
