defmodule Magpie.PageController do
  @moduledoc false
  use MagpieWeb, :controller

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:magpie, :no_basic_auth) do
    plug(BasicAuth, use_config: {:magpie, :authentication})
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
