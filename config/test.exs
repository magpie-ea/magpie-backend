use Mix.Config

config :babe, BABE.Endpoint,
  http: [port: 4001],
  # Enable the server during tests
  server: true

# Configure your database
config :babe, BABE.Repo,
  username: "babe_dev",
  password: "babe",
  database: "babe_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :babe, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Used for basic_auth
config :babe, :authentication,
  username: "default",
  password: "password"

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Experimental.Chrome

config :babe, :environment, :test
