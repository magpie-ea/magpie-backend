defmodule WoqWebapp.ExperimentController do
  @moduledoc false
  use WoqWebapp.Web, :controller
  require Logger
  require Iteraptor

  alias WoqWebapp.Experiment

  import WoqWebapp.ExperimentHelper

  def create(conn, raw_params) do
    # I'll just manually modify the params a bit before passing it into the changeset function of the model layer, apparently.

    # I can get rid of the meta information here actually. Why keep them in the final JSON anyways?
    params_without_meta = Map.drop(raw_params, ["author", "experiment_id", "description"])

    # No need to worry about error handling here since if any of the fields is missing, it will become `nil` only. The validation defined in the model layer will notice the error, and later :unprocessable_entity will be sent.
    params = %{author: raw_params["author"], experiment_id: raw_params["experiment_id"], description: raw_params["description"], results: params_without_meta}

    changeset = Experiment.changeset(%Experiment{}, params)
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

  #  write_results = [:experiments_empty, :IO_failure, :success]
  # def retrieve(conn, %{"experiment" => %{"experiment_id" => experiment_id, "author" => author}}) do
  def retrieve(conn, experiment_params) do
    experiment_id = experiment_params["experiment"]["experiment_id"]
    author = experiment_params["experiment"]["author"]
    query = from e in WoqWebapp.Experiment,
                 where: e.experiment_id == ^experiment_id,
                 where: e.author == ^author

    # This should return a list
    experiments = Repo.all(query)

    case experiments do
      # In this case this thing is just empty. I'll render error message later.
      [] ->
        conn
        |> put_flash(:error, "The experiment with the given id and author cannot be found!")
        # I'll render an error message later...
#        |> render(conn, "index.html")
       |> redirect(to: experiment_path(conn, :query))
      # Hopefully this can prevent any race condition/clash.
      _ ->
        file_name = "results_" <> experiment_id <> "_" <> author <> ".csv"
        file = File.open!("./results/" <> file_name, [:write, :utf8])
        write_experiments(file, experiments)
        File.close(file)
        conn
        |> put_flash(:info, "The experiment file is retrieved successfully.")
        |> redirect(to: "/results/" <> file_name)
        # |> redirect(to: experiment_path(conn, :query))
#        |> render(conn, "index.html")
    end
  end

end
