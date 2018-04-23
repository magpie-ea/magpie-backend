# Now it is actually better called "ExperimentResult", since I'll create another model for experiment management. But anyways let's keep it first?
defmodule ProComPrag.ExperimentResult do
  @moduledoc """
  An ExperimentResult corresponds to a set of results obtained from one participant finishing one complete experiment, which usually consists of several trials.
  """

  use ProComPrag.Web, :model

  schema "experiment_results" do
    # This is a map, representing the whole JSON object received when the experiment was first submitted.
    # Maybe the name `data` would be more appropriate. But anyways. Don't want to have troubles with migrations so
    # let's just keep it for now.
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
    # `cast/3` ignores all parameters not explicitly permitted, converts all permitted key names into atoms, and store them in the :changes field of the changeset
    # The point is that only the :changes field will work when performing any real DB action with Repo.
    # This is to say, the other parameters are not "deleted" at this step yet. You can chain multiple `cast` calls.
    |> cast(params, [:experiment_id, :author])
      # Validate the required parameters are all there. In our case all parameters are required.
    |> validate_required([:experiment_id, :author])
  end

  # Changeset function for `submit` function.
  # Though admittedly in our case `cast` is rather useless since `:results` actually contains everything from the incoming JSON file anyways, as is specified by our experiment.
  # Are there actually attack vectors from storing and retrieving jsonb in Postgres?
  # One way to handle this potential problem is to ask the experimenter to specify all the parameters of an experiment beforehand. though I'm not sure if it's worth the trouble.
  # Surely if the attacker is really to attack by using some malicious input, he can use the existing keys in the experiment all the same?
  # Anyways, this submitted serialized JSON should be safe enough. Let's just do it this way first.
  def submit_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, [:results, :description])
    |> validate_required([:results, :description])
    |> validate_trials_exists()
    |> transform_trials()
  end

  def construct_experiment_query(experiment_id, author) do
    from e in "experiments",
    where: e.experiment_id == ^experiment_id,
    where: e.author == ^author
  end

  def retrieve_changeset(model, params \\ %{}) do
    model
    |> cast(params, [:experiment_id, :author])
    |> validate_required([:experiment_id, :author])
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

  defp transform_trials(changeset) do
    results = get_field(changeset, :results)
    case results["trials"] do
      nil -> changeset
      trials ->
        # This only happens when the data is submitted incorrectly, i.e. without specifying application/json as the
        # Content-Type in the request header.
        if is_map(trials) do
          new_trials = ProComPrag.ExperimentHelper.convert_trials(trials)
          new_results = Map.put(results, "trials", new_trials)
          put_change(changeset, :results, new_results)
        else
          changeset
        end
    end
  end
end
