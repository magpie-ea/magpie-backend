defmodule Magpie.PageController do
  @moduledoc false
  use MagpieWeb, :controller

  # Don't ask for authentication if it's run on the user's local machine or a system variable is explicitly set (e.g. on the Heroku public demo)
  unless Application.get_env(:magpie, :no_basic_auth) do
    import Plug.BasicAuth
    username = Application.get_env(:magpie, :authentication)[:username]
    password = Application.get_env(:magpie, :authentication)[:password]
    plug :basic_auth, username: username, password: password
  end

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
