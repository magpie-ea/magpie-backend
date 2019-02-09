use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :babe, BABE.Endpoint,
  http: [port: 4001],
  server: false

# Configure your database
config :babe, BABE.Repo,
  adapter: Sqlite.Ecto2,
  database: "babe_db.sqlite3",
  priv: "priv/local_repo",
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn

# Used for basic_auth
config :babe, :authentication,
  username: "default",
  password: "password"

config :babe, :environment, :test
