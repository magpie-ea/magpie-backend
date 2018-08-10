defmodule BABE.PageController do
  @moduledoc false
  use BABE.Web, :controller
  plug(BasicAuth, use_config: {:babe, :authentication})

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
