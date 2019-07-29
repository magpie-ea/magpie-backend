defmodule Magpie.CustomRecordView do
  use Magpie.Web, :view

  def get_endpoint_url(type, id) do
    base_url = Application.get_env(:magpie, :real_url, Magpie.Endpoint.url())
    path = Magpie.Router.Helpers.custom_record_path(Magpie.Endpoint, type, id)
    base_url <> path
  end
end
