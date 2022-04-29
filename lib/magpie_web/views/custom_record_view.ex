defmodule Magpie.CustomRecordView do
  use MagpieWeb, :view

  def get_endpoint_url(type, id) do
    Magpie.Router.Helpers.custom_record_url(Magpie.Endpoint, type, id)
  end
end
