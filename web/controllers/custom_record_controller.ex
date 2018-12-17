defmodule BABE.CustomRecordController do
  @moduledoc false
  use BABE.Web, :controller
  plug(BasicAuth, use_config: {:babe, :authentication})

  alias BABE.CustomRecord

  # Used for retrieve_as_csv
  import BABE.CustomRecordHelper

  def index(conn, _params) do
    custom_records = Repo.all(CustomRecord |> order_by(asc: :id))
    render(conn, "index.html", custom_records: custom_records)
  end

  def new(conn, _params) do
    changeset = CustomRecord.changeset(%CustomRecord{})
    render(conn, "new.html", changeset: changeset)
  end

  defp convert_uploaded_data(upload) do
    case upload.content_type do
      "application/json" ->
        upload.path
        |> File.read!()
        |> Poison.decode!()

      "text/csv" ->
        upload.path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        # We shouldn't need to manually verify that the rows are valid. The decode! should do it for us
        # |> Stream.filter(fn({k, v}) -> k == :ok end)
        # |> Stream.map(fn({k, v}) -> v end)
        |> Enum.take_every(1)

      _ ->
        nil
    end
  end

  def create(conn, %{"custom_record" => custom_record_params}) do
    upload = custom_record_params["record"]

    try do
      content = convert_uploaded_data(upload)

      if content == nil do
        conn
        |> put_flash(:error, "Make sure the file extension is either .csv or .json")
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )
        |> halt
      end

      changeset =
        CustomRecord.changeset(%CustomRecord{
          name: custom_record_params["name"],
          record: content
        })

      case Repo.insert(changeset) do
        {:ok, custom_record} ->
          conn
          |> put_flash(:info, "#{custom_record.name} created!")
          |> redirect(to: custom_record_path(conn, :index))

        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    rescue
      UndefinedFunctionError ->
        conn
        |> put_flash(:error, "No file selected.")
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )

      _ ->
        conn
        |> put_flash(
          :error,
          "Some rows/contents in the file weren't able to be parsed correctly. Please check the formatting."
        )
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    custom_record = Repo.get!(CustomRecord, id)
    changeset = CustomRecord.changeset(custom_record)
    render(conn, "edit.html", custom_record: custom_record, changeset: changeset)
  end

  def update(conn, %{"id" => id, "custom_record" => custom_record_params}) do
    custom_record = Repo.get!(CustomRecord, id)

    upload = custom_record_params["record"]

    try do
      content = convert_uploaded_data(upload)

      if content == nil do
        conn
        |> put_flash(:error, "Make sure the file extension is either .csv or .json")
        |> render("edit.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )
        |> halt
      end

      changeset =
        CustomRecord.changeset(custom_record, %{
          name: custom_record_params["name"],
          record: content
        })

      case Repo.update(changeset) do
        {:ok, custom_record} ->
          conn
          |> put_flash(:info, "#{custom_record.name} updated successfully.")
          |> redirect(to: custom_record_path(conn, :index))

        {:error, changeset} ->
          render(conn, "edit.html", custom_record: custom_record, changeset: changeset)
      end
    rescue
      UndefinedFunctionError ->
        conn
        |> put_flash(:error, "No file selected.")
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )

      _ ->
        conn
        |> put_flash(
          :error,
          "Some rows/contents in the file weren't able to be parsed correctly. Please check the formatting."
        )
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    custom_record = Repo.get!(CustomRecord, id)

    Repo.delete!(custom_record)

    conn
    |> put_flash(:info, "CustomRecord #{custom_record.name} deleted successfully.")
    |> redirect(to: custom_record_path(conn, :index))
  end

  def retrieve_as_csv(conn, %{"id" => id}) do
    custom_record = Repo.get!(CustomRecord, id)

    name = custom_record.name
    id = custom_record.id

    # Name the CSV file to be returned.
    orig_name = "record_" <> id <> "_" <> name <> ".csv"
    file_path = "results/" <> orig_name
    file = File.open!(file_path, [:write, :utf8])
    # This method actually processes the submissions retrieved and write them to the CSV file.
    write_record(file, custom_record.record)
    File.close(file)

    conn
    |> send_download({:file, file_path})
  end

  def retrieve_as_json(conn, %{"id" => id}) do
    # This is the "CustomRecord" object that's supposed to be associated with this request.
    custom_record = Repo.get(CustomRecord, id)

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

  def retrieve_all(conn, _params) do
    all_files =
      CustomRecord
      |> Repo.all()
      |> Enum.reduce([], fn custom_record, acc ->
        id = custom_record.id
        name = custom_record.name

        file_path = "results/" <> "record_" <> id <> "_" <> name <> ".csv"
        file = File.open!(file_path, [:write, :utf8])
        write_record(file, custom_record.record)
        File.close(file)

        # :zip is an Erlang function. We need to convert Elixir string to Erlang charlist.
        [String.to_charlist(file_path) | acc]
      end)

    :zip.create('results/all_records.zip', all_files)

    conn
    |> send_download({:file, "results/all_records.zip"})
  end
end
