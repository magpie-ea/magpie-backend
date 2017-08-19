defmodule WoqWebapp.Endpoint do
  use Phoenix.Endpoint, otp_app: :woq_webapp

  socket "/socket", WoqWebapp.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :woq_webapp, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # The result files to be retrieved.
  plug Plug.Static,
    at: "/results", from: "/results", gzip: false
    # at: "/results", from: Path.expand("results/"), gzip: false

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_woq_webapp_key",
    signing_salt: "MmqUE5bg"

  plug WoqWebapp.Router
end
