defmodule WoqWebapp.PageController do
  use WoqWebapp.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
