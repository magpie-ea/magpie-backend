defmodule Magpie.ExperimentView do
  use MagpieWeb, :view
  import Ecto.Query, only: [from: 2]

  # From https://medium.com/@chipdean/phoenix-array-input-field-implementation-7ec0fe0949d
  def array_input(form, field) do
    values = Phoenix.HTML.Form.input_value(form, field) || [""]
    id = Phoenix.HTML.Form.input_id(form, field)
    type = Phoenix.HTML.Form.input_type(form, field)

    content_tag :ol,
      id: container_id(id),
      class: "input_container",
      data: [index: Enum.count(values)] do
      values
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        new_id = id <> "_#{index}"

        input_opts = [
          name: new_field_name(form, field),
          value: value,
          id: new_id,
          class: "form-control"
        ]

        form_elements(form, field, value, index)
      end)
    end
  end

  defp form_elements(form, field, value, index) do
    type = Phoenix.HTML.Form.input_type(form, field)
    id = Phoenix.HTML.Form.input_id(form, field)
    new_id = id <> "_#{index}"

    input_opts = [
      name: new_field_name(form, field),
      value: value,
      id: new_id,
      class: "form-control"
    ]

    content_tag :li do
      [
        apply(Phoenix.HTML.Form, type, [form, field, input_opts]),
        link("Remove", to: "#", data: [id: new_id], title: "Remove", class: "remove-form-field")
      ]
    end
  end

  defp container_id(id), do: id <> "_container"

  defp new_field_name(form, field) do
    Phoenix.HTML.Form.input_name(form, field) <> "[]"
  end

  def array_add_button(form, field) do
    id = Phoenix.HTML.Form.input_id(form, field)

    content =
      form
      |> form_elements(field, "", "__name__")
      |> safe_to_string

    data = [
      prototype: content,
      container: container_id(id)
    ]

    link("Add", to: "#", data: data, class: "add-form-field")
  end

  @doc """
  For dynamic experiment results retrieval as JSON over HTTP. Only render the keys specified in the UI.
  """
  def render("retrieval.json", %{keys: keys, submissions: submissions}) do
    Enum.map(submissions, &transform_submission(&1, keys))
  end

  defp transform_submission(submission, keys) do
    # Here, each "result" is a JSON array of JSON objects (trials) with the same set of keys
    # Simply check if the keys are specified.
    submission.results
    |> Enum.map(fn trial ->
      trial
      |> Enum.filter(fn {k, _v} -> Enum.member?(keys, k) end)
      |> Map.new()
    end)
  end

  @doc """
  Get the total number of submissions for a particular experiment
  """
  def get_current_submissions(experiment) do
    query =
      from(r in Magpie.Experiments.ExperimentResult, where: r.experiment_id == ^experiment.id)

    Magpie.Repo.aggregate(query, :count, :id)
  end

  # TODO: Optimize the query a bit, or use some sort of caching
  def get_last_submission_time(experiment) do
    query =
      from(r in Magpie.Experiments.ExperimentResult,
        where: r.experiment_id == ^experiment.id,
        order_by: [desc: r.updated_at],
        select: r.updated_at,
        limit: 1
      )

    case Magpie.Repo.one(query) do
      # No submissions whatsoever. Use the experiment itself.
      nil -> experiment.updated_at
      t -> t
    end
  end

  def get_endpoint_url(type, id) do
    base_url = Application.get_env(:magpie, :real_url, Magpie.Endpoint.url())
    path = Magpie.Router.Helpers.experiment_path(Magpie.Endpoint, type, id)
    base_url <> path
  end

  def get_socket_url() do
    base_url = Application.get_env(:magpie, :real_url, Magpie.Endpoint.url())
    ws_url = String.replace_leading(base_url, "http", "ws")
    ws_url <> "/socket"
  end

  def format_timestamp(timestamp, timezone) do
    timestamp
    |> Calendar.DateTime.shift_zone!(timezone)
    |> Calendar.Strftime.strftime!("%Y-%m-%d %H:%M")
  end

  def format_timestamp(timestamp) do
    timezone = Application.get_env(:magpie, :timezone, "Etc/UTC")
    format_timestamp(timestamp, timezone)
  end
end
