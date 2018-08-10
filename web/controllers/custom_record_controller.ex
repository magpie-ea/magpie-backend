defmodule BABE.CustomRecordController do
  @moduledoc false
  use BABE.Web, :controller
  plug(BasicAuth, use_config: {:babe, :authentication})

  alias BABE.CustomRecord

  def index(conn, _params) do
    custom_records = Repo.all(CustomRecord |> order_by(asc: :id))
    render(conn, "index.html", custom_records: custom_records)
  end

  def new(conn, _params) do
    changeset = CustomRecord.changeset(%CustomRecord{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"custom_record" => custom_record_params}) do
    upload = custom_record_params["record"]

    try do
      csv_content =
        upload.path
        |> File.stream!()
        |> CSV.decode!(headers: true)
        # We shouldn't need to manually verify that the rows are valid. The decode! should do it for us
        # |> Stream.filter(fn({k, v}) -> k == :ok end)
        # |> Stream.map(fn({k, v}) -> v end)
        |> Enum.take_every(1)

      changeset =
        CustomRecord.changeset(%CustomRecord{
          name: custom_record_params["name"],
          record: csv_content
        })

      case Repo.insert(changeset) do
        {:ok, custom_record} ->
          conn
          |> put_flash(:info, "#{custom_record.name} created and set to active!")
          |> redirect(to: custom_record_path(conn, :index))

        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    rescue
      UndefinedFunctionError ->
        conn
        |> put_flash(:error, "No CSV file selected.")
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )

      _ ->
        conn
        |> put_flash(
          :error,
          "Some rows in the CSV file weren't able to be parsed correctly. Please check the formatting."
        )
        |> render("new.html",
          changeset: CustomRecord.changeset(%CustomRecord{name: custom_record_params["name"]})
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    custom_record = Repo.get!(CustomRecord, id)
    changeset = CustomRecord.changeset(custom_record)
    render(conn, "edit.html", record: custom_record, changeset: changeset)
  end
end
