use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :babe, BABE.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: ["node_modules/brunch/bin/brunch", "watch", "--stdin", cd: Path.expand("../", __DIR__)]
  ]

# Watch static and templates for browser reloading.
config :babe, BABE.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/[^.#].*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :babe, BABE.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "babe_dev",
  password: "babe",
  # This is the current workaround. "db" is the host name for the Docker postgres container. "localhost" when you actually run it with your system's postgres instead of through Docker.
  hostname:
    (if System.get_env("DOCKER") == "true" do
       "db"
     else
       "localhost"
     end),
  database: "babe_dev",
  pool_size: 10

# Used for basic_auth
config :babe, :authentication,
  username: "default",
  password: "password"

config :babe, :environment, :dev

# See https://github.com/phoenixframework/phoenix/issues/1199. Seems that it suffices in most cases to keep the passwords in this file.
# import_config "dev.secret.exs"
