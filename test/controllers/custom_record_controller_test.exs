defmodule CustomRecordControllerTest do
  @moduledoc false

  use BABE.ConnCase
  alias BABE.{Repo, CustomRecord}

  @username Application.get_env(:babe, :authentication)[:username]
  @password Application.get_env(:babe, :authentication)[:password]

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
          # Currently it's just a simple 401 text response. But the browser should know to ask the client to authenticate, seeing this situation, anyways.
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

      assert redirected_to(conn) == custom_record_path(conn, :index)
    end

    # test "create/2 does not allow uploading an empty CSV file",
    #      %{conn: conn} do
    #   csv = %Plug.Upload{
    #     path: "test/fixtures/custom_record_empty.csv",
    #     content_type: "text/csv",
    #     filename: "custom_record.csv"
    #   }

    #   conn =
    #     conn
    #     |> using_basic_auth()
    #     |> post("/custom_records", %{
    #       "custom_record" => %{
    #         "name" => "some name",
    #         "record" => csv
    #       }
    #     })

    #   # assert html_response(conn, 200) =~ "check the formatting"
    #   assert html_response(conn, 200) =~ "alert"
    # end

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

      # assert html_response(conn, 200) =~ "check the formatting"
      assert html_response(conn, 200) =~ "alert"
    end

    test "create/2 successfully creates a custom record with a valid JSON upload", %{conn: conn} do
      csv = %Plug.Upload{
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
            "record" => csv
          }
        })

      assert redirected_to(conn) == custom_record_path(conn, :index)
    end
  end
end
