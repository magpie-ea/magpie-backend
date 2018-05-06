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
    # We want to also display the count of ExperimentResult for each experiment.
    # Guess currently the most straightforward way is to run a map on all those experiments and query the DB for the count... which might be slow though.
    # Just add a field for it? It doesn't sound the most elegant way but it could be a more efficient alternative I suppose.
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

    # Needs to perform some manual processing on the :dynamic_retrieval_keys param out there.
    # Might as well use empty list as the default value here.
    # experiment_params = Map.update(experiment_params, "dynamic_retrieval_keys", [], &String.split(&1, [",", " "]))

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
        # IO.puts(current_submissions + 1)
        # IO.puts(experiment.maximum_submissions)
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

  # Currently seems to be no need for that. The edit page suffices
  # def show(conn, %{"id" => id}) do
  # end

  def edit(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    changeset = Experiment.changeset(experiment)
    render(conn, "edit.html", experiment: experiment, changeset: changeset)
  end

  # Currently no need for this since there is a form solution.
  # defp transform_dynamic_retrieval_keys(experiment) do
  #   experiment[""]

  #   experiment_params = Map.update(experiment_params, "dynamic_retrieval_keys", [], &String.split(&1, [",", " "]))
  # end

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

  # def check_duplicate(conn, params) do

  # end

end
