defmodule Hello.Exp1cController do
  @moduledoc false
  use Hello.Web, :controller

  def receive(conn, params) do
    # This will just render the exact same JSON back. Though it will actually also send 200 in the end.
    # json(conn, %{body: params})
    send_resp(conn, 200, "")
  end
end
