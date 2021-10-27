defmodule Magpie.PageController do
  @moduledoc false
  use MagpieWeb, :controller

  import Plug.BasicAuth

  plug :basic_auth,
    username: Application.get_env(:magpie, :authentication)[:username],
    password: Application.get_env(:magpie, :authentication)[:password]

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
