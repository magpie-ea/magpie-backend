import Config

config :magpie, Magpie.Endpoint,
  http: [port: 4001],
  # Enable the server during tests
  server: true

# Configure your database
config :magpie, Magpie.Repo,
  username: "magpie_dev",
  password: "magpie",
  database: "magpie_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :magpie, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Used for basic_auth
config :magpie, :authentication,
  username: "default",
  password: "password"

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Chrome

config :magpie, :environment, :test

config :magpie,
       :no_basic_auth,
       false
