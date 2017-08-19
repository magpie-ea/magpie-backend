defmodule ProComPrag.PageController do
  use ProComPrag.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
