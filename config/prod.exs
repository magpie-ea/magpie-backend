use Mix.Config

config :logger,
  level: :info

config :magpie, :environment, :prod

config :magpie, MagpieWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [hsts: true]

# We don't have a basic auth on the demo app, so we need to allow for this flexibility
# Deliberate compile-time variable
config :magpie,
       :no_basic_auth,
       false
