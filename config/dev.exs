use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :magpie, Magpie.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :magpie, Magpie.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/magpie_web/(live|views)/.*(ex)$",
      ~r"lib/magpie_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :magpie, Magpie.Repo,
  username: "magpie_dev",
  password: "magpie",
  # This is the current workaround. "db" is the host name for the Docker postgres container. "localhost" when you actually run it with your system's postgres instead of through Docker.
  hostname:
    (if System.get_env("DOCKER") == "true" do
       "db"
     else
       "localhost"
     end),
  database: "magpie_dev",
  pool_size: 10

# No real need for basic auth in dev
config :magpie,
       :no_basic_auth,
       true

config :magpie, :environment, :dev

# See https://github.com/phoenixframework/phoenix/issues/1199. Seems that it suffices in most cases to keep the passwords in this file.
# import_config "dev.secret.exs"
