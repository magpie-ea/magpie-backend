defmodule Magpie.ExperimentController do
  @moduledoc false
  use MagpieWeb, :controller

  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment

  import Plug.BasicAuth

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:magpie, :no_basic_auth) do
    username = Application.get_env(:magpie, :authentication)[:username]
    password = Application.get_env(:magpie, :authentication)[:password]

    plug :basic_auth,
         [username: username, password: password]
         when action not in [:submit, :retrieve_as_json, :check_valid]
  end

  def index(conn, _params) do
    render(conn, "index.html", experiments: Experiments.list_experiments())
  end

  @doc """
  Page to create an experiment record
  """
  def new(conn, _params) do
    changeset = Experiment.changeset(%Experiment{})
    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Function called when an experiment record creation request is submitted (from `new`)
  """
  def create(conn, %{"experiment" => experiment_params}) do
    case Experiments.create_experiment(experiment_params) do
      {:ok, %{experiment: experiment}} ->
        conn
        |> put_flash(:info, "#{experiment.name} created!")
        |> redirect(to: experiment_path(conn, :edit, experiment))

      {:error, :experiment, failed_value, _changes_so_far} ->
        conn
        |> render("new.html", changeset: failed_value)

      # The failure doesn't lie in experiment creation
      {:error, _, failed_value, _changes_so_far} ->
        conn
        |> render("new.html", changeset: failed_value)

      _ ->
        conn
        |> render("new.html", changeset: Experiment.changeset(%Experiment{}))
    end
  end

  def edit(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)
    changeset = Experiment.changeset(experiment)
    render(conn, "edit.html", experiment: experiment, changeset: changeset)
  end

  def update(conn, %{"id" => id, "experiment" => experiment_params}) do
    # If all the keys are removed, we need to reset it to nil.
    experiment_params = Map.put_new(experiment_params, "dynamic_retrieval_keys", nil)
    experiment = Experiments.get_experiment!(id)

    case Experiments.update_experiment(experiment, experiment_params) do
      {:ok, experiment} ->
        conn
        |> put_flash(:info, "Experiment #{experiment.name} updated successfully.")
        |> redirect(to: experiment_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", experiment: experiment, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    id
    |> Experiments.get_experiment!()
    |> Experiments.delete_experiment!()

    conn
    |> put_flash(:info, "Experiment deleted successfully.")
    |> redirect(to: experiment_path(conn, :index))
  end

  def toggle(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)

    case Experiments.toggle_experiment(experiment) do
      {:ok, experiment} ->
        conn
        |> put_flash(
          :info,
          "The activation status has been successfully changed to #{experiment.active}"
        )
        |> redirect(to: experiment_path(conn, :edit, experiment))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "The activation status wasn't changed successfully!")
        |> redirect(to: experiment_path(conn, :edit, experiment))
    end
  end

  @doc """
  Resets an experiment, i.e. delete all results and reset all statuses!
  """
  def reset(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)

    case Experiments.reset_experiment(experiment) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "The experiment has been reset!")
        |> redirect(to: experiment_path(conn, :edit, experiment))

      {:error, _, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(
          :error,
          "Oops, something went wrong when resetting this experiment. You could create a new experiment instead."
        )
        |> redirect(to: experiment_path(conn, :edit, experiment))
    end
  end

  ## Below are the endpoints related to the API with the frontend.

  @doc """
  Stores a set of experiment results submitted via the API

  Note that the incoming JSON array of experiment results is automatically parsed and put under the key _json:
  https://hexdocs.pm/plug/Plug.Parsers.JSON.html

  The "id" field is identifiable in the URL, as defined in router.ex
  """
  def submit(conn, %{"id" => id, "_json" => results}) do
    # This is the "Experiment" object that's supposed to be associated with this submission.
    experiment = Experiments.get_experiment(id)

    case experiment do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          404,
          "No experiment with the specified id found. Please check your configuration."
        )

      _ ->
        case experiment.active do
          false ->
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(
              403,
              "The experiment is not active at the moment and submissions are not allowed."
            )

          true ->
            case Experiments.create_experiment_result(experiment, results) do
              {:ok, _} ->
                send_resp(conn, :created, "")

              {:error, _changeset} ->
                # unprocessable entity is 422
                conn
                |> put_resp_content_type("text/plain")
                |> send_resp(
                  :unprocessable_entity,
                  "Unsuccessful submission. The results are probably malformed. Ensure that the results are submitted as an array of JSON objects, and that each object contains the same set of keys."
                )
            end
        end
    end
  end

  @doc """
  Check whether the given experiment_id is valid before the participant starts the experiment on the frontend.
  """
  def check_valid(conn, %{"id" => id}) do
    case Experiments.get_experiment(id) do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          404,
          "No experiment with the specified id found. Please check your configuration."
        )

      experiment ->
        case experiment.active do
          true ->
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(200, "The experiment exists and is active")

          false ->
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(
              403,
              "The experiment is not active at the moment and submissions are not allowed."
            )
        end
    end
  end

  @doc """
  Retrieves the results up to now for an experiment in CSV format.
  """
  def retrieve_as_csv(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)

    case Experiments.retrieve_experiment_results_as_csv(experiment) do
      {:error, :no_submissions_yet} ->
        conn
        |> put_flash(:error, "No submissions for this experiment yet!")
        |> redirect(to: experiment_path(conn, :index))

      {:ok, file_path} ->
        download_name = "results_#{experiment.id}_#{experiment.name}_#{experiment.author}.csv"

        conn
        |> send_download({:file, file_path},
          content_type: "application/csv",
          filename: download_name
        )

      _ ->
        conn
        |> put_flash(:error, "Unknown error")
        |> redirect(to: experiment_path(conn, :index))
    end
  end

  @doc """
  Retrieves the results up to now for an experiment in JSON format.
  """
  def retrieve_as_json(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment(id)

    case Experiments.retrieve_experiment_results_as_json(experiment) do
      {:ok, experiment_results} ->
        render(conn, "retrieval.json",
          keys: experiment.dynamic_retrieval_keys,
          submissions: experiment_results
        )

      {:nil_experiment, true} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          404,
          "No experiment with the author and name combination found. Please check your configuration."
        )

      {:nil_keys, true} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(403, "Please specify the keys for retrieval (in the user interface)!")

      {:empty_results, true} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(404, "No submissions for this experiment recorded yet.")

      _ ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(403, "Unknown error")
    end
  end
end
