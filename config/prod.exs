use Mix.Config

config :babe, BABE.Endpoint,
  http: [port: 4000],
  # Replace the host with your own application URL!
  url: [scheme: "http", host: "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json",
  # Needed for Distillery releases
  server: true,
  # Allow clients from anywhere to connect to use the interactive experiment facilities. We can't constrain where the user chooses to host the frontend anyways.
  check_origin: false

# Configure the database
config :babe, BABE.Repo,
  adapter: Sqlite.Ecto2,
  database: "babe_db.sqlite3",
  priv: "priv/local_repo"

# Do not print debug messages in production
config :logger, level: :info

config :babe, :no_basic_auth, true

config :babe, :environment, :prod

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :babe, BABE.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :babe, BABE.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :babe, BABE.Endpoint, server: true
#
