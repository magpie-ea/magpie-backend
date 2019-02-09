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
  adapter: Sqlite.Ecto2,
  database: "babe_db.sqlite3",
  priv: "priv/local_repo"

# Used for basic_auth
config :babe, :no_basic_auth, true

config :babe, :environment, :dev

# See https://github.com/phoenixframework/phoenix/issues/1199. Seems that it suffices in most cases to keep the passwords in this file.
# import_config "dev.secret.exs"
