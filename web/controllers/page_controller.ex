defmodule BABE.PageController do
  @moduledoc false
  use BABE.Web, :controller

  if Application.get_env(:babe, :environment) != :local do
    plug(BasicAuth, use_config: {:babe, :authentication})
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
