defmodule PageControllerTest do
  @moduledoc false

  use Magpie.ConnCase
  alias Magpie.{Repo, ExperimentResult, ExperimentStatus}

  @username Application.get_env(:magpie, :authentication)[:username]
  @password Application.get_env(:magpie, :authentication)[:password]
  defp using_basic_auth(conn, username \\ @username, password \\ @password) do
    header_content = "Basic " <> Base.encode64("#{username}:#{password}")
    conn |> put_req_header("authorization", header_content)
  end

  test "Requires authentication for accessing the landing page", %{conn: conn} do
    conn =
      conn
      |> get(page_path(conn, :index))

    assert text_response(conn, 401)
    assert conn.halted
  end
end
