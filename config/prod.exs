import Config

config :logger,
  level: :info

config :magpie, :environment, :prod

config :magpie, MagpieWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [hsts: true]
