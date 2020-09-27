# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :magpie,
  ecto_repos: [Magpie.Repo]

# Configures the endpoint
config :magpie, Magpie.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "mUum0f5OpF/oj91tE+XldtHDV5RzRCwZ6GxdF3KDj1lau8GI6dq7HsB1pRMA5Z3z",
  render_errors: [view: Magpie.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Magpie.PubSub, adapter: Phoenix.PubSub.PG2],
  instrumenters:
    (if System.get_env("USE_TIMBER") == "true" do
       [Timber.Phoenix]
     else
       []
     end)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# The local timezone where the app is deployed.
config :magpie, :timezone, "Europe/Berlin"

config :magpie,
       :no_basic_auth,
       (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
          true
        else
          false
        end)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
