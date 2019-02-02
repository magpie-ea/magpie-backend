defmodule BABE.ExperimentController do
  @moduledoc false
  use BABE.Web, :controller

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:babe, :no_basic_auth) do
    plug(
      BasicAuth,
      [use_config: {:babe, :authentication}]
      when not (action in [:submit, :retrieve_as_json, :check_valid])
    )
  end

  alias BABE.{Experiment, ExperimentResult}
  alias Ecto.Multi

  import BABE.ExperimentHelper

  def index(conn, _params) do
    # Repo.all takes a query argument.
    experiments = Repo.all(Experiment |> order_by(asc: :id))
    render(conn, "index.html", experiments: experiments)
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
    case create_experiment(experiment_params) do
      # We can just pattern match on one of the keys in the map. It's fine.
      {:ok, %{experiment: experiment}} ->
        conn
        |> put_flash(:info, "#{experiment.name} created!")
        |> redirect(to: experiment_path(conn, :index))

      {:error, :experiment, failed_value, _changes_so_far} ->
        conn
        # |> put_flash(:error, "Sorry, something went wrong.")
        |> render("new.html", changeset: failed_value)

      # The failure doesn't lie in experiment creation
      {:error, _, _failed_value, _changes_so_far} ->
        conn
        # |> put_flash(:error, "Sorry, something went wrong.")
        |> render("new.html")
    end
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
      {:ok, experiment} ->
        # TODO: Now we need to decide what to do to the experiment status trackers.
        # It will be pretty weird. Sounds a kind of like some strange 3-D algebra, in that I'll have to remove excessive ExperimentStatus and add previously nonexistent ExperimentStatus
        # Is that a reasonable approach after all? Not sure.
        # OK I think the case of increasing any number in the trituple is easier to handle: Just create new ExperimentStatus entries and that will be it
        # But the case of reducing any number will be really annoying.
        # Now let me just make the trituple uneditable after experiment creation anyways.
        conn
        |> put_flash(:info, "Experiment #{experiment.name} updated successfully.")
        |> redirect(to: experiment_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", experiment: experiment, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)

    Repo.delete!(experiment)

    conn
    |> put_flash(:info, "Experiment deleted successfully.")
    |> redirect(to: experiment_path(conn, :index))
  end

  def toggle(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)
    new_status = !experiment.active
    changeset = Ecto.Changeset.change(experiment, active: new_status)

    if new_status == false do
      BABE.ExperimentHelper.reset_in_progress_experiment_statuses()
    end

    case Repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(
          :info,
          "The activation status has been successfully changed to #{new_status}"
        )
        |> redirect(to: experiment_path(conn, :edit, experiment))

      {:error, _} ->
        conn
        |> put_flash(:error, "The activation status wasn't changed successfully!")
        |> redirect(to: experiment_path(conn, :edit, experiment))
    end
  end

  @doc """
  Resets an experiment, i.e. delete all results and reset all statuses!
  """
  def reset(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)

    multi =
      Multi.new()
      |> Multi.delete_all(:experiment_results, assoc(experiment, :experiment_results))
      |> Multi.update_all(:experiment_statuses, assoc(experiment, :experiment_statuses),
        set: [status: 0]
      )

    case BABE.Repo.transaction(multi) do
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

  ## Below are the functions related to the API with the frontend.

  @doc """
  Stores a set of experiment results submitted via the API

  Note that the incoming JSON array of experiment results is automatically parsed and put under the key _json:
  https://hexdocs.pm/plug/Plug.Parsers.JSON.html

  The "id" field is identifiable in the URL, as defined in router.ex
  """
  def submit(conn, %{"id" => id, "_json" => results}) do
    # This is the "Experiment" object that's supposed to be associated with this submission.
    experiment = Repo.get(Experiment, id)

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
            record_submission(conn, results, experiment)
        end
    end
  end

  defp record_submission(conn, results, experiment) do
    changeset =
      experiment
      # This creates an ExperimentResult struct with the :experiment_id field filled in
      |> build_assoc(:experiment_results)
      |> ExperimentResult.changeset(%{"results" => results})

    case Repo.insert(changeset) do
      # Update the submission count
      {:ok, _} ->
        # Currently I don't think there's a need to send the created resource back. Just acknowledge that the information is received.
        # created is 201
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

  def retrieve_as_csv(conn, %{"id" => id}) do
    experiment = Repo.get!(Experiment, id)

    id = experiment.id
    name = experiment.name
    author = experiment.author
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
        orig_name = "results_#{id}_#{name}_#{author}.csv"
        file_path = "results/#{orig_name}"
        file = File.open!(file_path, [:write, :utf8])
        # This method actually processes the submissions retrieved and write them to the CSV file.
        write_submissions(file, experiment_submissions)
        File.close(file)

        conn
        |> send_download({:file, file_path})
    end
  end

  @doc """
  Retrieves the results up to now for an experiment.
  """
  def retrieve_as_json(conn, %{"id" => id}) do
    # This is the "Experiment" object that's supposed to be associated with this request.
    experiment = Repo.get(Experiment, id)

    case experiment do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          404,
          "No experiment with the author and name combination found. Please check your configuration."
        )

      _ ->
        case experiment.dynamic_retrieval_keys do
          nil ->
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(403, "Please specify the keys for retrieval (in the user interface)!")

          _ ->
            experiment_results = Repo.all(assoc(experiment, :experiment_results))

            case experiment_results do
              [] ->
                conn
                |> put_resp_content_type("text/plain")
                |> send_resp(404, "No submissions for this experiment recorded yet.")

              _ ->
                render(conn, "retrieval.json",
                  keys: experiment.dynamic_retrieval_keys,
                  submissions: experiment_results
                )
            end
        end
    end
  end

  # By default the second argument is _params even though it might not be used in a controller function.
  @doc """
  Retrieve all experiment results as a zip of CSVs.
  """
  def retrieve_all(conn, _params) do
    all_files =
      Experiment
      |> Repo.all()
      |> Enum.reduce([], fn experiment, acc ->
        id = experiment.id
        name = experiment.name
        author = experiment.author
        experiment_submissions = Repo.all(assoc(experiment, :experiment_results))

        case experiment_submissions do
          # If the experiment still has no submissions, just skip it.
          [] ->
            acc

          _ ->
            file_path = "results/" <> "results_" <> id <> "_" <> name <> "_" <> author <> ".csv"
            file = File.open!(file_path, [:write, :utf8])
            write_submissions(file, experiment_submissions)
            File.close(file)

            # :zip is an Erlang function. We need to convert Elixir string to Erlang charlist.
            [String.to_charlist(file_path) | acc]
        end
      end)

    :zip.create('results/all_results.zip', all_files)

    conn
    |> send_download({:file, "results/all_results.zip"})
  end

  @doc """
  Check whether the given experiment_id is valid before the participant ever starts.
  """
  def check_valid(conn, %{"id" => id}) do
    case Repo.get(Experiment, id) do
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
end
