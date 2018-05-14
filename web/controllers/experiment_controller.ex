defmodule ProComPrag.ExperimentController do
  @moduledoc false
  use ProComPrag.Web, :controller
  plug BasicAuth, [use_config: {:procomprag, :authentication}] when not action in [:submit, :retrieve_as_json]
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
        |> put_flash(:info, "#{experiment.name} created and set to active!")
        |> redirect(to: experiment_path(conn, :index))
      {:error, changeset} ->
        # The error message is already included in the template file and will be rendered by then.
        render(conn, "new.html", changeset: changeset)
    end
  end

  @doc """
  Stores a set of experiment results submitted via the API
  """
  def submit(conn, %{"id" => id, "_json" => results}) do
    # This is the "Experiment" object that's supposed to be associated with this submission.
    experiment = Repo.get(Experiment, id)

    case experiment do
      nil -> conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "No experiment with the author and name combination found. Please check your configuration.")
      _ -> case experiment.active do
             false -> conn
               |> put_resp_content_type("text/plain")
               |> send_resp(403, "The experiment is not active at the moment and submissions are not allowed.")
             true -> if valid_results(results) do record_submission(conn, results, experiment) else conn |> send_resp(400, "The results are not submitted as a JSON array, or each object of the array does not contain the same set of keys.") end
            end
    end
  end

  defp record_submission(conn, results, experiment) do
    changeset =
      experiment
      # This creates an ExperimentResult struct with the name field filled in
      |> build_assoc(:experiment_results)
      |> ExperimentResult.changeset(%{"results" => results})

    case Repo.insert(changeset) do
      {:ok, _} -> # Update the submission count
        # No need to do this for now. Just count the number of associated ExperimentResult entries should work.
        current_submissions = experiment.current_submissions
        changeset_experiment = Ecto.Changeset.change experiment, current_submissions: current_submissions + 1
        # Automatically set the experiment to inactive if the maximum submission is reached.
        changeset_experiment =
          if current_submissions + 1 >= experiment.maximum_submissions do
            Ecto.Changeset.put_change(changeset_experiment, :active, false)
          else
            changeset_experiment
          end
        Repo.update! changeset_experiment
        # Currently I don't think there's a need to send the created resource back. Just acknowledge that the information is received.
        # created is 201
        send_resp(conn, :created, "")
      {:error, changeset} ->
        # unprocessable entity is 422
        IO.puts(changeset)
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:unprocessable_entity, "Unsuccessful submission. The results are probably malformed.")
    end
  end

  def retrieve_as_csv(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)

    name = experiment.name
    author = experiment.author
    # experiments = get_experiment_submissions(experiment)

    experiment_submissions = Repo.all(assoc(experiment, :experiment_results))

    case experiment_submissions do
      # In this case nothing could be found in the DB.
      [] ->
        conn
        # Render the error message.
        |> put_flash(:error, "No submissions for this experiment yet!")
        |> redirect(to: experiment_path(conn, :index))

      _ ->
        # Name the CSV file to be returned.
        orig_name = "results_" <> name <> "_" <> author <> ".csv"
        file_path =
        # On Heroku the app is in the /app/ folder.
        if Application.get_env(:my_app, :environment) == :prod do
          "/app/results/" <> orig_name
        else
          "results/" <> orig_name
        end
        file = File.open!(file_path, [:write, :utf8])
        # This method actually processes the submissions retrieved and write them to the CSV file.
        write_submissions(file, experiment_submissions)
        File.close(file)

        conn
        |> send_download({:file, file_path})
    end
  end

  # Use this for "dynamic retrieval"
  def show(conn, %{"id" => id}) do
  end

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
      {:ok, _experiment} ->
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
  def retrieve_as_json(conn, %{"id" => id}) do
    # This is the "Experiment" object that's supposed to be associated with this request.
    experiment = Repo.get(Experiment, id)

    case experiment do
      nil -> conn
            |> put_resp_content_type("text/plain")
            |> send_resp(404, "No experiment with the author and name combination found. Please check your configuration.")
      _ -> case experiment.dynamic_retrieval_keys do
        nil -> conn
          |> put_resp_content_type("text/plain")
          |> send_resp(403, "Please specify the keys for retrieval (in the user interface)!")
          _ ->
            experiment_results = Repo.all(assoc(experiment, :experiment_results))
            case experiment_results do
              [] -> conn
              |> put_resp_content_type("text/plain")
              |> send_resp(404, "No submissions for this experiment recorded yet.")
              _ ->
                  render(conn, "retrieval.json", keys: experiment.dynamic_retrieval_keys, submissions: experiment_results)
            end
          end
        end
  end

  def toggle(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    active = experiment.active
    changeset = Ecto.Changeset.change experiment, active: !active

    case Repo.update changeset do
      {:ok, struct} ->
        conn
        |> put_flash(:info, "The activation status has been successfully changed to #{!active}")
        |> redirect(to: experiment_path(conn, :edit, experiment))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "The activation status wasn't changed successfully!")
        |> redirect(to: experiment_path(conn, :edit, experiment))
    end
  end

end
