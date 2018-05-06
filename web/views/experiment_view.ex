defmodule ProComPrag.ExperimentView do
  use ProComPrag.Web, :view

  # From https://medium.com/@chipdean/phoenix-array-input-field-implementation-7ec0fe0949d
def array_input(form, field) do
    values = Phoenix.HTML.Form.input_value(form, field) || [""]
    id = Phoenix.HTML.Form.input_id(form, field)
    type = Phoenix.HTML.Form.input_type(form, field)
    content_tag :ol, id: container_id(id), class: "input_container", data: [index: Enum.count(values)] do
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
    content = form
      |> form_elements(field, "", "__name__")
      |> safe_to_string
    data = [
      prototype: content,
      container: container_id(id)
    ]
    link("Add", to: "#", data: data, class: "add-form-field")
  end
end
