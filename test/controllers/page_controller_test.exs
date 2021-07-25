defmodule PageControllerTest do
  @moduledoc false

  use Magpie.ConnCase

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

    assert response(conn, 401)
    assert conn.halted
  end

  describe "index/2" do
    test "index/2 shows the landing page", %{conn: conn} do
      conn =
        conn
        |> using_basic_auth()
        |> get("/")

      assert html_response(conn, 200) =~
               "Minimal Architecture for the Generation of Portable Interactive Experiments"
    end
  end
end
