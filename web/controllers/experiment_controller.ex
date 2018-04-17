defmodule ProComPrag.ExperimentController do
  @moduledoc false
  use ProComPrag.Web, :controller
  require Logger
  require Iteraptor

  alias ProComPrag.Experiment

  import ProComPrag.ExperimentHelper

  def create(conn, raw_params) do
    # The meta information is to be inserted into the DB as standalone keys.
    # Therefore they are excluded from the JSON file here.
    params_without_meta = Map.drop(raw_params, ["author", "experiment_id", "description"])

    # No need to worry about error handling here since if any of the fields is missing, it will become `nil` only. The validation defined in the model layer will notice the error, and later :unprocessable_entity will be sent.
    params = %{author: raw_params["author"], experiment_id: raw_params["experiment_id"], description: raw_params["description"], results: params_without_meta}

    changeset =  Experiment.create_changeset(%Experiment{}, params)

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
    changeset = Experiment.changeset(%Experiment{})
    render conn, "query.html", changeset: changeset
  end

  def retrieve(conn, %{"experiment" => experiment_params}) do
    # First check whether the password is right.
    # password = experiment_params["password"]
    # These two are used as keys to query the DB.
    experiment_id = experiment_params["experiment_id"]
    author = experiment_params["author"]
    query = from e in ProComPrag.Experiment,
                 where: e.experiment_id == ^experiment_id,
                 where: e.author == ^author

    # This should return a list of submissions (results)
    experiments = Repo.all(query)

    case experiments do
      # In this case nothing could be found in the DB.
      [] ->
        conn
        # Render the error message.
        |> put_flash(:error, "The experiment with the given id and author cannot be found!")
        |> redirect(to: experiment_path(conn, :query))

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

end
