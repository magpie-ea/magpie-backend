import Config

config :logger,
  level: :info

config :magpie, :environment, :prod

config :magpie, MagpieWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [hsts: true]

# We don't have a basic auth on the demo app, so we need to allow for this flexibility
# Deliberate compile-time variable.
config :magpie,
       :no_basic_auth,
       (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
          true
        else
          false
        end)

# Used for basic_auth
# Note that on the magpie-demo app this will not be used.
# Note these are compile-time variables since they are now fetched when `router.ex` is compiled.
config :magpie, :authentication,
  username: System.fetch_env!("AUTH_USERNAME"),
  password: System.fetch_env!("AUTH_PASSWORD")
