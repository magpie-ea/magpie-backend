defmodule WoqWebapp.Experiment do
  @moduledoc false

  use WoqWebapp.Web, :model

  schema "experiments" do
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
    query = from e in "experiments",
            where: e.experiment_id == ^experiment_id,
            where: e.author == ^author
  end

end
