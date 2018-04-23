defmodule ProComPrag.ExperimentController do
  @moduledoc false
  use ProComPrag.Web, :controller
  require Logger
  require Iteraptor

  alias ProComPrag.Experiment
  alias ProComPrag.ExperimentResult

  import ProComPrag.ExperimentHelper

  def index(conn, _params) do
    experiments = Repo.all(Experiment)
    render(conn, "index.html", experiments: experiments)
  end

  @doc """
  Page to create an experiment record
  """
  def new(conn, _params) do
    changeset = Experiment.changeset(%Experiment{})
    render conn, "new.html", changeset: changeset
  end

  @doc """
  Function called when an experiment record creation request is submitted (from `new`)
  """
  def create(conn, %{"experiment" => experiment_params}) do
    # Add password check later

    # experiment_id = experiment_params["experiment_id"]
    # author = experiment_params["author"]

    changeset = Experiment.changeset(%Experiment{}, experiment_params)

    case Repo.insert(changeset) do
      {:ok, experiment} ->
        conn
        |> put_flash(:info, "#{experiment.experiment_id} created and set to active!")
        |> redirect(to: page_path(conn, :index))
      {:error, changeset} ->
        # The error message is already included in the template file and will be rendered by then.
        render(conn, "new.html", changeset: changeset)
    end
  end

  @doc """
  Stores a set of experiment results submitted via the API
  """
  def submit(conn, raw_params) do
    # The meta information is to be inserted into the DB as standalone keys.
    # Therefore they are excluded from the JSON file here.
    params_without_meta = Map.drop(raw_params, ["author", "experiment_id", "description"])

    # No need to worry about error handling here since if any of the fields is missing, it will become `nil` only. The validation defined in the model layer will notice the error, and later :unprocessable_entity will be sent.
    params = %{author: raw_params["author"], experiment_id: raw_params["experiment_id"], description: raw_params["description"], results: params_without_meta}

    changeset =  ExperimentResult.submit_changeset(%ExperimentResult{}, params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        # Currently I don't think there's a need to send the created resource back. Just acknowledge that the information is received.
        # created is 201
        send_resp(conn, :created, "")
      {:error, _} ->
        # unprocessable entity is 422
        send_resp(conn, :unprocessable_entity, "")
    end
  end

  def query(conn, _params) do
    changeset = ExperimentResult.changeset(%ExperimentResult{})
    render conn, "query.html", changeset: changeset
  end

  def retrieve(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    # First check whether the password is right.
    # password = experiment_params["password"]
    # These two are used as keys to query the DB.
    experiment_id = experiment.experiment_id
    author = experiment.author
    query = from e in ProComPrag.ExperimentResult,
                 where: e.experiment_id == ^experiment_id,
                 where: e.author == ^author

    # This should return a list of submissions (results)
    experiments = Repo.all(query)

    case experiments do
      # In this case nothing could be found in the DB.
      [] ->
        conn
        # Render the error message.
        |> put_flash(:error, "No results for this experiment yet!")
        |> redirect(to: experiment_path(conn, :index))

      _ ->
        # Name the CSV file to be returned.
        orig_name = "results_" <> experiment_id <> "_" <> author <> ".csv"
        file_path =
        # On Heroku the app is in the /app/ folder.
        if Application.get_env(:my_app, :environment) == :prod do
          "/app/results/" <> orig_name
        else
          "results/" <> orig_name
        end
        file = File.open!(file_path, [:write, :utf8])
        # This method actually processes the results retrieved and write them to the CSV file.
        write_experiments(file, experiments)
        File.close(file)

        conn
        # The flash doesn't work very well since the page wasn't refreshed anyways.
        # |> put_flash(:info, "The experiment file is retrieved successfully.")
        |> send_download({:file, file_path})
    end
  end

  def toggle(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    active = experiment.active
    experiment = Ecto.Changeset.change experiment, active: !active

    case Repo.update experiment do
      {:ok, struct} ->
        conn
        |> put_flash(:info, "The activation status has been successfully changed to #{!active}")
        |> redirect(to: experiment_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "The activation status wasn't changed successfully!")
        |> redirect(to: experiment_path(conn, :index))
    end

  end

end
