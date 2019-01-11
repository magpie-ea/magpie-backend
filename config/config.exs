# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :babe,
  ecto_repos: [BABE.Repo]

# Configures the endpoint
config :babe, BABE.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "mUum0f5OpF/oj91tE+XldtHDV5RzRCwZ6GxdF3KDj1lau8GI6dq7HsB1pRMA5Z3z",
  render_errors: [view: BABE.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BABE.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# The local timezone where the app is deployed.
config :babe, :timezone, "Europe/Berlin"

config :babe, :no_basic_auth, System.get_env("NO_BASIC_AUTH") || "false"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
