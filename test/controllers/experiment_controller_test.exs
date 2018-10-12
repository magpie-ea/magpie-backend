defmodule ExperimentControllerTest do
  @moduledoc false

  use BABE.ConnCase

  # test "POST Experiment", %{conn: conn} do
  # end

  test "Requires authentication for administrating experiments", %{conn: conn} do
    Enum.each(
      [
        get(conn, experiment_path(conn, :index)),
        get(conn, experiment_path(conn, :new)),
        post(conn, experiment_path(conn, :create, %{})),
        get(conn, experiment_path(conn, :edit, "123")),
        put(conn, experiment_path(conn, :update, "123")),
        delete(conn, experiment_path(conn, :delete, "123")),
        get(conn, experiment_path(conn, :toggle, "123"))
      ],
      fn conn ->
        # Currently it's just a simple 401 text response. But the browser should know to ask the client to authenticate, seeing this situation, anyways.
        assert text_response(conn, 401)
        assert conn.halted
      end
    )
  end
end
