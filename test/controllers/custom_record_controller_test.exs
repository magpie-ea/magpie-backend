defmodule CustomRecordControllerTest do
  @moduledoc false

  use Magpie.ConnCase
  alias Magpie.{Repo, CustomRecord}

  @username Application.get_env(:magpie, :authentication)[:username]
  @password Application.get_env(:magpie, :authentication)[:password]

  @simple_record [%{"a" => "1", "b" => "2"}, %{"a" => "11", "b" => "22"}]

  defp using_basic_auth(conn, username \\ @username, password \\ @password) do
    header_content = "Basic " <> Base.encode64("#{username}:#{password}")
    conn |> put_req_header("authorization", header_content)
  end

  describe "basic_auth" do
    test "Requires authentication for administrating custom records", %{conn: conn} do
      Enum.each(
        [
          get(conn, custom_record_path(conn, :index)),
          get(conn, custom_record_path(conn, :new)),
          post(conn, custom_record_path(conn, :create, %{})),
          get(conn, custom_record_path(conn, :edit, "123")),
          put(conn, custom_record_path(conn, :update, "123")),
          delete(conn, custom_record_path(conn, :delete, "123")),
          get(conn, custom_record_path(conn, :retrieve_as_csv, "123"))
        ],
        fn conn ->
          assert text_response(conn, 401)
          assert conn.halted
        end
      )
    end

    test "The API endpoint doesn't require authentication", %{conn: conn} do
      Enum.each(
        [
          get(conn, custom_record_path(conn, :retrieve_as_json, "123"))
        ],
        fn conn ->
          refute conn.status == 401
        end
      )
    end
  end

  describe "index/2" do
    test "index/2 responds with all custom records", %{conn: conn} do
      insert_custom_record()
      insert_custom_record(%{name: "some other name"})

      conn =
        conn
        |> using_basic_auth()
        |> get("/custom_records")

      assert html_response(conn, 200) =~ "some name"
      assert html_response(conn, 200) =~ "some other name"
    end
  end

  describe "new/2" do
    test "new/2 responds with the custom record creation page", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> get("/custom_records/new")

      assert html_response(conn, 200) =~ "Create a New Custom Record"
      assert html_response(conn, 200) =~ "Submit"
    end
  end

  describe "create/2" do
    test "create/2 successfully creates a custom record with a valid CSV upload", %{conn: conn} do
      csv = %Plug.Upload{
        path: "test/fixtures/custom_record.csv",
        content_type: "text/csv",
        filename: "custom_record.csv"
      }

      conn =
        conn
        |> using_basic_auth()
        |> post("/custom_records", %{
          "custom_record" => %{
            "name" => "some name",
            "record" => csv
          }
        })

      record = Repo.one!(CustomRecord).record
      assert(record == @simple_record)
      assert redirected_to(conn) == custom_record_path(conn, :index)
    end

    test "create/2 does not allow uploading an empty CSV file",
         %{conn: conn} do
      csv = %Plug.Upload{
        path: "test/fixtures/custom_record_empty.csv",
        content_type: "text/csv",
        filename: "custom_record.csv"
      }

      conn =
        conn
        |> using_basic_auth()
        |> post("/custom_records", %{
          "custom_record" => %{
            "name" => "some name",
            "record" => csv
          }
        })

      assert(nil == Repo.one(CustomRecord))
      assert html_response(conn, 200) =~ "alert"
    end

    test "create/2 does not allow a CSV upload with some empty entries",
         %{conn: conn} do
      csv = %Plug.Upload{
        path: "test/fixtures/custom_record_with_empty_entries.csv",
        content_type: "text/csv",
        filename: "custom_record.csv"
      }

      conn =
        conn
        |> using_basic_auth()
        |> post("/custom_records", %{
          "custom_record" => %{
            "name" => "some name",
            "record" => csv
          }
        })

      assert(nil == Repo.one(CustomRecord))
      assert html_response(conn, 200) =~ "alert"
    end

    test "create/2 successfully creates a custom record with a valid JSON upload", %{conn: conn} do
      json = %Plug.Upload{
        path: "test/fixtures/custom_record.json",
        content_type: "application/json",
        filename: "custom_record.json"
      }

      conn =
        conn
        |> using_basic_auth()
        |> post("/custom_records", %{
          "custom_record" => %{
            "name" => "some name",
            "record" => json
          }
        })

      record = Repo.one!(CustomRecord).record
      assert(record == @simple_record)
      assert redirected_to(conn) == custom_record_path(conn, :index)
    end

    test "create/2 does not allow an empty JSON upload", %{conn: conn} do
      json = %Plug.Upload{
        path: "test/fixtures/custom_record_empty.json",
        content_type: "application/json",
        filename: "custom_record.json"
      }

      conn =
        conn
        |> using_basic_auth()
        |> post("/custom_records", %{
          "custom_record" => %{
            "name" => "some name",
            "record" => json
          }
        })

      assert(nil == Repo.one(CustomRecord))
      assert html_response(conn, 200) =~ "alert"
    end
  end

  describe "edit/2" do
    test "edit/2 responds with the custom records edit page", %{conn: conn} do
      custom_record = insert_custom_record()

      conn =
        conn
        |> using_basic_auth()
        |> get("/custom_records/#{custom_record.id}/edit")

      assert html_response(conn, 200) =~ "Edit Custom Record"
      assert html_response(conn, 200) =~ "Submit"
    end
  end

  describe "delete/2" do
    test "delete/2 succeeds and redirects to the experiment index page", %{conn: conn} do
      custom_record = insert_custom_record()

      conn =
        conn
        |> using_basic_auth()
        |> delete("/custom_records/#{custom_record.id}")

      assert redirected_to(conn) == custom_record_path(conn, :index)
      assert nil == Magpie.Repo.get(CustomRecord, custom_record.id)
    end
  end

  describe "retrieve_as_csv/2" do
    test "retrieve_as_csv/2 produces a CSV file with expected contents", %{conn: conn} do
      custom_record = insert_custom_record()

      conn =
        conn
        |> using_basic_auth()
        |> get(custom_record_path(conn, :retrieve_as_csv, custom_record.id))

      file = response(conn, 200)

      assert(file == "a,b\r\n1,2\r\n11,22\r\n")
    end
  end

  describe "retrieve_as_json/2" do
    test "Dynamic retrieval returns exactly the data specified", %{conn: conn} do
      custom_record = insert_custom_record(%{dynamic_retrieval_keys: ["a"]})

      conn =
        conn
        |> using_basic_auth()
        |> get(custom_record_path(conn, :retrieve_as_json, custom_record.id))

      data = response(conn, 200) |> Jason.decode!()

      assert(data == [%{"a" => 1, "b" => 2}, %{"a" => 11, "b" => 22}])
    end

    test "Dynamic retrieval returns 404 for a nonexisting custom_record", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> get(custom_record_path(conn, :retrieve_as_json, 1234))

      assert(response(conn, 404))
    end
  end
end
