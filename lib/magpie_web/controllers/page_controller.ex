defmodule Magpie.PageController do
  @moduledoc false
  use MagpieWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
