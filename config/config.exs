# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :magpie,
  ecto_repos: [Magpie.Repo]

# Configures the endpoint
config :magpie, Magpie.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "mUum0f5OpF/oj91tE+XldtHDV5RzRCwZ6GxdF3KDj1lau8GI6dq7HsB1pRMA5Z3z",
  render_errors: [view: Magpie.ErrorView, accepts: ~w(html json)],
  pubsub_server: Magpie.PubSub,
  # In all envs server needs to be turned on (in test we run Wallaby)
  server: true

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# The local timezone where the app is deployed.
config :magpie, :timezone, "Europe/Berlin"

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
