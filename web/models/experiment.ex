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

  # Used for param validation etc. Now let's skip this step first
  def changeset(model, params \\ %{}) do
    model
    # `cast/3` ensures that only the allowed parameters are let through, and that the input is safe.
    |> cast(params, [:results, :experiment_id, :author, :description])
    # Validate the required parameters are all there. In our case all parameters are required.
    |> validate_required([:results, :experiment_id, :author, :description])
  end

  def construct_experiment_query(experiment_id, author) do
    from e in "experiments",
    where: e.experiment_id == ^experiment_id,
    where: e.author == ^author
  end

end
