defmodule BABE.CustomRecordView do
  use BABE.Web, :view

  def get_endpoint_url(type, id) do
    base_url = Application.get_env(:babe, :real_url, BABE.Endpoint.url())
    path = BABE.Router.Helpers.custom_record_path(BABE.Endpoint, type, id)
    base_url <> path
  end
end
