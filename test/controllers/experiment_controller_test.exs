defmodule ExperimentControllerTest do
  @moduledoc false

  use Magpie.ConnCase
  alias Magpie.Experiments.{Experiment, ExperimentResult, ExperimentStatus}
  alias Magpie.Repo

  @username Application.get_env(:magpie, :authentication)[:username]
  @password Application.get_env(:magpie, :authentication)[:password]
  @results_simple_experiment [%{"a" => "1", "b" => "2"}, %{"a" => "11", "b" => "22"}]

  defp using_basic_auth(conn, username \\ @username, password \\ @password) do
    header_content = "Basic " <> Base.encode64("#{username}:#{password}")
    conn |> put_req_header("authorization", header_content)
  end

  describe "basic_auth" do
    test "Requires authentication for administrating experiments", %{conn: conn} do
      Enum.each(
        [
          get(conn, experiment_path(conn, :index)),
          get(conn, experiment_path(conn, :new)),
          post(conn, experiment_path(conn, :create, %{})),
          get(conn, experiment_path(conn, :edit, "123")),
          put(conn, experiment_path(conn, :update, "123")),
          delete(conn, experiment_path(conn, :delete, "123")),
          get(conn, experiment_path(conn, :toggle, "123")),
          get(conn, experiment_path(conn, :retrieve_as_csv, "123"))
        ],
        fn conn ->
          # Currently it's just a simple 401 text response. But the browser should know to ask the client to authenticate, seeing this situation, anyways.
          assert response(conn, 401)
          assert conn.halted
        end
      )
    end

    test "The API endpoints don't require authentication", %{conn: conn} do
      Enum.each(
        [
          post(
            conn,
            experiment_path(conn, :submit, "123"),
            %{
              "_json" => [%{"a" => 1, "b" => 2}, %{"a" => 3, "b" => 4}]
            }
          ),
          get(conn, experiment_path(conn, :retrieve_as_json, "123")),
          get(conn, experiment_path(conn, :check_valid, "123"))
        ],
        fn conn ->
          refute conn.status == 401
        end
      )
    end
  end

  describe "index/2" do
    test "index/2 responds with all experiments", %{conn: conn} do
      insert_experiment()
      insert_experiment(%{name: "some other name", author: "some other author"})

      conn =
        conn
        |> using_basic_auth()
        |> get("/experiments")

      # The name of the first experiment
      assert html_response(conn, 200) =~ "some name"
      # The name of the other experiment
      assert html_response(conn, 200) =~ "some other name"
    end
  end

  describe "new/2" do
    test "new/2 responds with the experiment creation page", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> get("/experiments/new")

      assert html_response(conn, 200) =~ "Create a New Experiment"
      assert html_response(conn, 200) =~ "Submit"
    end
  end

  describe "create/2" do
    test "create/2 successfully creates a simple experiment with valid attributes", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> post("/experiments", %{"experiment" => get_experiment_attrs()})

      assert html_response(conn, 302) =~ "You are being"
    end

    test "create/2 fails with invalid attributes and redirects to creation page", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> post("/experiments", %{"experiment" => Map.delete(get_experiment_attrs(), :author)})

      assert html_response(conn, 200) =~ "Something is wrong."
    end

    # This should usually be put into the context testing module. Since we don't use contexts yet, guess we can only put it here for now.
    test "Corresponding ExperimentStatus entries are created together with dynamic experiments" do
      experiment = insert_dynamic_experiment()

      all_experiment_statuses = Magpie.Repo.all(ExperimentStatus, experiment_id: experiment.id)

      assert length(all_experiment_statuses) ==
               experiment.num_variants * experiment.num_generations * experiment.num_chains
    end
  end

  describe "edit/2" do
    test "edit/2 responds with the experiment edit page", %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> using_basic_auth()
        |> get("/experiments/#{experiment.id}/edit")

      assert html_response(conn, 200) =~ "Edit Experiment"
      assert html_response(conn, 200) =~ "Submit"
    end
  end

  describe "update/2" do
    test "update/2 correctly updates the experiment name", %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> using_basic_auth()
        |> put(experiment_path(conn, :update, "#{experiment.id}"), %{
          "experiment" => %{name: "New Name"}
        })

      assert redirected_to(conn) == experiment_path(conn, :index)
      updated_experiment = Magpie.Repo.get(Experiment, experiment.id)
      assert updated_experiment.name == "New Name"
    end
  end

  describe "delete/2" do
    test "delete/2 succeeds and redirects to the experiment index page", %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> using_basic_auth()
        |> delete("/experiments/#{experiment.id}")

      assert redirected_to(conn) == experiment_path(conn, :index)
      assert nil == Magpie.Repo.get(Experiment, experiment.id)
    end

    # TODO: These two tests should also be refactored and put into a "context test" module.
    test "Related ExperimentResult entries are also deleted after deleting an experiment", %{
      conn: conn
    } do
      experiment = insert_experiment()
      insert_experiment_result(%{"experiment_id" => experiment.id})
      insert_experiment_result(%{"experiment_id" => experiment.id})

      all_experiment_results = Magpie.Repo.all(ExperimentResult, experiment_id: experiment.id)

      assert length(all_experiment_results) == 2

      conn
      |> using_basic_auth()
      |> delete("/experiments/#{experiment.id}")

      all_experiment_results = Magpie.Repo.all(ExperimentResult, experiment_id: experiment.id)

      assert Enum.empty?(all_experiment_results)
    end

    test "Related ExperimentStatus entries are also deleted after deleting a dynamic experiment",
         %{conn: conn} do
      experiment = insert_dynamic_experiment()
      all_experiment_statuses = Magpie.Repo.all(ExperimentStatus, experiment_id: experiment.id)

      assert length(all_experiment_statuses) ==
               experiment.num_variants * experiment.num_generations * experiment.num_chains

      conn
      |> using_basic_auth()
      |> delete("/experiments/#{experiment.id}")

      all_experiment_statuses = Magpie.Repo.all(ExperimentStatus, experiment_id: experiment.id)

      assert Enum.empty?(all_experiment_statuses)
    end
  end

  describe "toggle/2" do
    test "toggle/2 toggles an active experiment to be inactive", %{
      conn: conn
    } do
      experiment = insert_experiment()

      conn
      |> using_basic_auth()
      |> get("/experiments/#{experiment.id}/toggle")

      experiment = Magpie.Repo.get!(Magpie.Experiments.Experiment, experiment.id)
      assert experiment.active == false
    end

    test "toggle/2 toggles an inactive experiment to be active", %{conn: conn} do
      experiment = insert_experiment(%{active: false})

      conn
      |> using_basic_auth()
      |> get("/experiments/#{experiment.id}/toggle")

      experiment = Magpie.Repo.get!(Magpie.Experiments.Experiment, experiment.id)
      assert experiment.active == true
    end

    test "toggle/2 resets all in progress experiments for an active experiment", %{conn: conn} do
      experiment = insert_dynamic_experiment()

      from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment.id,
        update: [set: [status: :in_progress]]
      )
      |> Repo.update_all([])

      conn
      |> using_basic_auth()
      |> get("/experiments/#{experiment.id}/toggle")

      experiment_statuses = Repo.all(ExperimentStatus, experiment_id: experiment.id)

      experiment_statuses_with_0 =
        experiment_statuses |> Enum.filter(fn status -> status.status == 0 end)

      assert length(experiment_statuses) == length(experiment_statuses_with_0)
    end

    test "toggle/2 doesn't reset any completed experiments' status", %{conn: conn} do
      experiment = insert_dynamic_experiment()

      from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment.id,
        update: [set: [status: :completed]]
      )
      |> Repo.update_all([])

      conn
      |> using_basic_auth()
      |> get("/experiments/#{experiment.id}/toggle")

      experiment_statuses = Repo.all(ExperimentStatus, experiment_id: experiment.id)

      experiment_statuses_with_0 =
        experiment_statuses |> Enum.filter(fn status -> status.status == 0 end)

      experiment_statuses_with_2 =
        experiment_statuses |> Enum.filter(fn status -> status.status == 2 end)

      assert Enum.empty?(experiment_statuses_with_0)
      assert length(experiment_statuses) == length(experiment_statuses_with_2)
    end
  end

  describe "reset/2" do
    test "Related ExperimentResult entries are deleted after resetting an experiment", %{
      conn: conn
    } do
      experiment = insert_experiment()
      insert_experiment_result(%{"experiment_id" => experiment.id})
      insert_experiment_result(%{"experiment_id" => experiment.id})

      all_experiment_results = Magpie.Repo.all(ExperimentResult, experiment_id: experiment.id)

      assert length(all_experiment_results) == 2

      conn
      |> using_basic_auth()
      |> delete("/experiments/#{experiment.id}/reset")

      all_experiment_results = Magpie.Repo.all(ExperimentResult, experiment_id: experiment.id)

      assert Enum.empty?(all_experiment_results)
    end

    test "Related ExperimentStatus have their :status field set to 0 after resetting an experiment",
         %{conn: conn} do
      experiment = insert_dynamic_experiment()

      from(s in ExperimentStatus,
        where: s.experiment_id == ^experiment.id,
        update: [set: [status: :completed]]
      )
      |> Repo.update_all([])

      conn
      |> using_basic_auth()
      |> delete("/experiments/#{experiment.id}/reset")

      experiment_statuses = Repo.all(ExperimentStatus, experiment_id: experiment.id)

      experiment_statuses_with_0 =
        experiment_statuses |> Enum.filter(fn status -> status.status == 0 end)

      assert length(experiment_statuses) == length(experiment_statuses_with_0)
    end
  end

  describe "check_valid/2" do
    test "Validity check returns 200 for an existing and valid experiment", %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> get(experiment_path(conn, :check_valid, experiment.id))

      assert text_response(conn, 200)
    end

    test "Validity check returns 404 for a nonexisting experiment", %{conn: conn} do
      conn =
        conn
        |> get(experiment_path(conn, :check_valid, :rand.uniform(1000)))

      assert text_response(conn, 404)
    end

    test "Validity check returns 403 for an existing but inactive experiment", %{conn: conn} do
      experiment = insert_experiment(%{active: false})

      conn =
        conn
        |> get(experiment_path(conn, :check_valid, experiment.id))

      assert text_response(conn, 403)
    end
  end

  describe "retrieve_as_csv/2" do
    test "retrieve_as_csv/2 produces a CSV file with expected contents", %{conn: conn} do
      experiment = insert_experiment()
      insert_experiment_result(%{"experiment_id" => experiment.id})
      submission_id = Repo.one!(ExperimentResult).id

      conn =
        conn
        |> using_basic_auth()
        |> get(experiment_path(conn, :retrieve_as_csv, experiment.id))

      file = response(conn, 200)

      # Note that the separator defaults to \r\n
      # Just directly match the content with the expected results anyways.
      assert(file == "submission_id,a,b\r\n#{submission_id},1,2\r\n#{submission_id},11,22\r\n")
    end
  end

  describe "retrieve_as_json/2" do
    test "Dynamic retrieval returns 403 if no keys are specified", %{conn: conn} do
      experiment = insert_experiment()
      insert_experiment_result(%{"experiment_id" => experiment.id})

      conn =
        conn
        |> using_basic_auth()
        |> get(experiment_path(conn, :retrieve_as_json, experiment.id))

      assert(response(conn, 403))
    end

    test "Dynamic retrieval returns exactly the data specified", %{conn: conn} do
      experiment = insert_experiment(%{dynamic_retrieval_keys: ["a"]})
      insert_experiment_result(%{"experiment_id" => experiment.id})
      # Insert twice so that we have two "participants" submitting their results
      insert_experiment_result(%{"experiment_id" => experiment.id})

      conn =
        conn
        |> using_basic_auth()
        |> get(experiment_path(conn, :retrieve_as_json, experiment.id))

      data = response(conn, 200) |> Jason.decode!()

      # List of lists, each inner list being one participant's responses
      assert(data == [[%{"a" => 1}, %{"a" => 11}], [%{"a" => 1}, %{"a" => 11}]])
    end

    test "Dynamic retrieval returns 404 for a nonexisting experiment", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> get(experiment_path(conn, :retrieve_as_json, 1234))

      assert(response(conn, 404))
    end

    test "Dynamic retrieval returns 404 for an existing experiment without any submissions", %{
      conn: conn
    } do
      experiment = insert_experiment(%{dynamic_retrieval_keys: ["a"]})

      conn =
        conn
        |> using_basic_auth()
        |> get(experiment_path(conn, :retrieve_as_json, experiment.id))

      assert(response(conn, 404))
    end

    # Maybe these should be view tests
    # test "Dynamic retrieval keys set in the UI get correctly stored to the DB", %{conn: conn} do
    # end

    # test "Deleting all dynamic retrieval keys gets reflected in the DB" do
    # end
  end

  describe "submit/2" do
    test "Submission of active experiment succeeds with 201 (created) and successfully stores the results in the DB",
         %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> post("api/submit_experiment/#{experiment.id}/", %{
          "_json" => @results_simple_experiment
        })

      results = Map.get(Repo.one!(ExperimentResult), :results)
      assert(results == @results_simple_experiment)
      assert(response(conn, :created))
    end

    test "Submission of inactive experiment fails with 403 and wouldn't store the data", %{
      conn: conn
    } do
      experiment = insert_experiment(%{active: false})

      conn =
        conn
        |> post("api/submit_experiment/#{experiment.id}/", %{
          "_json" => @results_simple_experiment
        })

      assert(nil == Repo.one(ExperimentResult))
      assert(response(conn, 403))
    end

    test "Submission of nonexistent experiment fails with 404 and wouldn't store the data", %{
      conn: conn
    } do
      conn =
        conn
        |> post("api/submit_experiment/1234/", %{
          "_json" => @results_simple_experiment
        })

      assert(nil == Repo.one(ExperimentResult))
      assert(response(conn, 404))
    end

    test "Submission of empty experiment results fails with 422 (unprocessable entity) and wouldn't store the data",
         %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> post("api/submit_experiment/#{experiment.id}/", %{
          "_json" => []
        })

      assert(nil == Repo.one(ExperimentResult))
      assert(response(conn, :unprocessable_entity))
    end

    test "Submission of malformed experiment results fails with 422 (unprocessable entity) and wouldn't store the data",
         %{conn: conn} do
      experiment = insert_experiment()

      conn =
        conn
        |> post("api/submit_experiment/#{experiment.id}/", %{
          "_json" => [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22, "c" => 123}]
        })

      assert(nil == Repo.one(ExperimentResult))
      assert(response(conn, :unprocessable_entity))
    end
  end
end
