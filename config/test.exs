import Config

config :magpie, Magpie.Endpoint,
  http: [port: 4001]

# Configure your database
config :magpie, Magpie.Repo,
  username: "postgres",
  password: "postgres",
  database: "magpie_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :magpie, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

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
