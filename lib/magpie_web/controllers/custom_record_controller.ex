defmodule Magpie.CustomRecordController do
  @moduledoc false
  use MagpieWeb, :controller
  alias Magpie.CustomRecords

  import Plug.BasicAuth

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:magpie, :no_basic_auth) do
    username = Application.get_env(:magpie, :authentication)[:username]
    password = Application.get_env(:magpie, :authentication)[:password]

    plug :basic_auth,
         [username: username, password: password] when action not in [:retrieve_as_json]
  end

  alias Magpie.CustomRecords.CustomRecord

  def index(conn, _params) do
    custom_records = Repo.all(CustomRecord |> order_by(asc: :id))
    render(conn, "index.html", custom_records: custom_records)
  end

  def new(conn, _params) do
    changeset = CustomRecord.changeset(%CustomRecord{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"custom_record" => custom_record_params}) do
    case CustomRecords.create_or_update_custom_record(custom_record_params) do
      {:ok, custom_record} ->
        conn
        |> put_flash(:info, "#{custom_record.name} created!")
        |> redirect(to: custom_record_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)

      {:error, :invalid_format} ->
        conn
        |> put_flash(:error, "Make sure the file extension is either .csv or .json")
        |> render("new.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )
        |> halt

      {:error, :no_file_selected} ->
        conn
        |> put_flash(:error, "No file selected.")
        |> render("new.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )

      {:error, :parse_failure} ->
        conn
        |> put_flash(
          :error,
          "Some rows/contents in the file weren't able to be parsed correctly. Please check the formatting."
        )
        |> render("new.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )

      _ ->
        conn
        |> put_flash(
          :error,
          "Unknown failure. Please try again."
        )
        |> render("new.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    custom_record = CustomRecords.get_custom_record!(id)
    changeset = CustomRecord.changeset(custom_record)
    render(conn, "edit.html", custom_record: custom_record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "custom_record" => custom_record_params}) do
    custom_record = CustomRecords.get_custom_record!(id)

    case CustomRecords.create_or_update_custom_record(custom_record_params, custom_record) do
      {:ok, custom_record} ->
        conn
        |> put_flash(:info, "#{custom_record.name} updated!")
        |> redirect(to: custom_record_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", custom_record: custom_record, changeset: changeset)

      {:error, :invalid_format} ->
        conn
        |> put_flash(:error, "Make sure the file extension is either .csv or .json")
        |> render("edit.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )
        |> halt

      {:error, :no_file_selected} ->
        conn
        |> put_flash(:error, "No file selected.")
        |> render("edit.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )

      {:error, :parse_failure} ->
        conn
        |> put_flash(
          :error,
          "Some rows/contents in the file weren't able to be parsed correctly. Please check the formatting."
        )
        |> render("edit.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )

      _ ->
        conn
        |> put_flash(
          :error,
          "Unknown failure. Please try again."
        )
        |> render("edit.html",
          changeset:
            CustomRecord.changeset(%CustomRecord{}, %{name: custom_record_params["name"]})
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    custom_record =
      id
      |> CustomRecords.get_custom_record!()
      |> CustomRecords.delete_custom_record!()

    conn
    |> put_flash(:info, "CustomRecord #{custom_record.name} deleted successfully.")
    |> redirect(to: custom_record_path(conn, :index))
  end

  def retrieve_as_csv(conn, %{"id" => id}) do
    custom_record = Repo.get!(CustomRecord, id)

    # Name the CSV file to be returned.
    download_name = "record_#{custom_record.id}_#{custom_record.name}.csv"

    {:ok, file_path} = CustomRecords.retrieve_custom_record_as_csv(custom_record)

    conn
    |> send_download({:file, file_path},
      content_type: "application/csv",
      filename: download_name
    )
  end

  def retrieve_as_json(conn, %{"id" => id}) do
    custom_record = CustomRecords.get_custom_record(id)

    case custom_record do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          404,
          "No custom_record with the id found. Please check your configuration."
        )

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> json(custom_record.record)
    end
  end
end
