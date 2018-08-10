defmodule BABE.PageController do
  @moduledoc false

  use BABE.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
