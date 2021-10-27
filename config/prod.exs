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

# Used for basic_auth
# However, we can't assume they always exist, since in some situations (e.g. demo app) we don't have any authentication.
# This will look a bit ugly... Will do for now.
# Compile-time!
config :magpie, :authentication,
  username: System.fetch_env!("AUTH_USERNAME"),
  password: System.fetch_env!("AUTH_PASSWORD")
