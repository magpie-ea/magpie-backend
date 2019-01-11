defmodule BABE.PageController do
  @moduledoc false
  use BABE.Web, :controller

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:babe, :environment) == :local ||
           System.get_env("NO_BASIC_AUTH") == "true" do
    plug(BasicAuth, use_config: {:babe, :authentication})
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
