defmodule ProComPrag.ExperimentController do
  @moduledoc false
  use ProComPrag.Web, :controller
  plug BasicAuth, [use_config: {:procomprag, :authentication}] when not action in [:submit, :dynamic_retrieve]
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

    changeset = Experiment.changeset(%Experiment{}, experiment_params)

    case Repo.insert(changeset) do
      {:ok, experiment} ->
        conn
        |> put_flash(:info, "#{experiment.experiment_id} created and set to active!")
        |> redirect(to: experiment_path(conn, :index))
      {:error, changeset} ->
        # The error message is already included in the template file and will be rendered by then.
        render(conn, "new.html", changeset: changeset)
    end
  end

  @doc """
  Stores a set of experiment results submitted via the API
  """
  def submit(conn, raw_params) do
    # This is the "Experiment" object that's supposed to be associated with this submission.
    experiment = Repo.get_by(Experiment, author: raw_params["author"], experiment_id: raw_params["experiment_id"])

    case experiment do
      nil -> conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "No experiment with the author and experiment_id combination found. Please check your configuration.")
      _ -> case experiment.active do
             false -> conn
               |> put_resp_content_type("text/plain")
               |> send_resp(403, "The experiment is not active at the moment and submissions are not allowed.")
             true -> record_submission(conn, raw_params, experiment)
            end
    end
  end

  defp record_submission(conn, raw_params, experiment) do
    # The meta information is to be inserted into the DB as standalone keys.
    # Therefore they are excluded from the JSON file here.
    params_without_meta = Map.drop(raw_params, ["author", "experiment_id", "description"])

    # No need to worry about error handling here since if any of the fields is missing, it will become `nil` only. The validation defined in the model layer will notice the error, and later :unprocessable_entity will be sent.
    params = %{author: raw_params["author"], experiment_id: raw_params["experiment_id"], description: raw_params["description"], results: params_without_meta}

    changeset =  ExperimentResult.submit_changeset(%ExperimentResult{}, params)

    case Repo.insert(changeset) do
      {:ok, _} -> # Update the submission count
        current_submissions = experiment.current_submissions
        changeset_experiment = Ecto.Changeset.change experiment, current_submissions: current_submissions + 1
        # Automatically set the experiment to inactive if the maximum submission is reached.
        if current_submissions + 1 >= experiment.maximum_submissions do
          changeset_experiment = Ecto.Changeset.put_change(changeset_experiment, :active, false)
        end
        Repo.update! changeset_experiment
        # Currently I don't think there's a need to send the created resource back. Just acknowledge that the information is received.
        # created is 201
        send_resp(conn, :created, "")
      {:error, _} ->
        # unprocessable entity is 422
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:unprocessable_entity, "Unsuccessful submission. The results are probably malformed. Probably check your trials object.")
    end
  end

  defp get_experiment_submissions(experiment) do
    # These two are used as keys to query the DB.
    experiment_id = experiment.experiment_id
    author = experiment.author
    query = from e in ProComPrag.ExperimentResult,
      where: e.experiment_id == ^experiment_id,
      where: e.author == ^author

    # This should return a list of submissions (results)
    Repo.all(query)
  end

  def retrieve(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    # First check whether the password is right.
    # password = experiment_params["password"]

    experiment_id = experiment.experiment_id
    author = experiment.author
    experiments = get_experiment_submissions(experiment)

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
        |> send_download({:file, file_path})
    end
  end

  # Currently seems to be no need for that. The edit page suffices
  # def show(conn, %{"id" => id}) do
  # end

  def edit(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    changeset = Experiment.changeset(experiment)
    render(conn, "edit.html", experiment: experiment, changeset: changeset)
  end

  def update(conn, %{"id" => id, "experiment" => experiment_params}) do
    # If all the keys are removed, we need to reset it to nil.
    experiment_params = Map.put_new(experiment_params, "dynamic_retrieval_keys", nil)
    experiment = Repo.get!(Experiment, id)
    changeset = Experiment.changeset(experiment, experiment_params)

    case Repo.update(changeset) do
      {:ok, experiment} ->
        conn
        |> put_flash(:info, "Experiment updated successfully.")
        |> redirect(to: experiment_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", experiment: experiment, changeset: changeset)
    end
  end

  @doc """
  Retrieves the results up to now for an experiment.
  """
  def dynamic_retrieve(conn, raw_params) do
    # This is the "Experiment" object that's supposed to be associated with this request.
    experiment = Repo.get_by(Experiment, author: raw_params["author"], experiment_id: raw_params["experiment_id"])

    case experiment do
      nil -> conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "No experiment with the author and experiment_id combination found. Please check your configuration.")
        _ -> case experiment.dynamic_retrieval_keys do
               nil -> conn
                 |> put_resp_content_type("text/plain")
                 |> send_resp(403, "Please specify the keys for retrieval (in the user interface)!")
                 _ ->
                   submissions = get_experiment_submissions(experiment)
                   case submissions do
                     [] -> conn
                     |> put_resp_content_type("text/plain")
                     |> send_resp(404, "No submissions for this experiment recorded yet.")
                     _ ->
                         IO.puts("Should be rendering")
                         render(conn, "retrieval.json", keys: experiment.dynamic_retrieval_keys, submissions: submissions)
                    end
                  end
                end

  end

  # def check_duplicate(conn, params) do

  # end

end
