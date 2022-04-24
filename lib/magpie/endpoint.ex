defmodule Magpie.Endpoint do
  use Phoenix.Endpoint, otp_app: :magpie

  # Enable concurrent testing.
  if Application.get_env(:magpie, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  # This is needed since the experiments are likely to be hosted on external domains.
  plug(CORSPlug)

  # By default we have one socket handler, which should suffice.
  socket("/socket", Magpie.ParticipantSocket)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :magpie,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_magpie_key",
    signing_salt: "MmqUE5bg"
  )

  plug(Magpie.Router)
end
