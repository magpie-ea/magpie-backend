import Config

config :magpie, Magpie.Endpoint,
  http: [port: System.get_env("PORT", "80") |> String.to_integer()],
  url: [
    scheme: System.get_env("URL_SCHEME", "https"),
    host: System.fetch_env!("HOST"),
    path: System.get_env("MAGPIE_PATH", "/"),
    port: System.get_env("PORT", "80") |> String.to_integer()
  ],
  # Don't use force_ssl if the URL_SCHEME is http
  # force_ssl:
  #   (if System.get_env("URL_SCHEME") == "http" do
  #      []
  #    else
  #      [rewrite_on: [:x_forwarded_proto]]
  #    end),
  server: true,
  # Allow clients from anywhere to connect to use the interactive experiment facilities. We can't constrain where the user chooses to host the frontend anyways.
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  check_origin: false,
  root: ".",
  version: Application.spec(:magpie, :vsn)

# Configure the database
config :magpie, Magpie.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL", "postgres:/magpie:magpie@localhost:5432/magpie_prod"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "2")),
  ssl: true,
  log: :debug

# Used for basic_auth
# However, we can't assume they always exist, since in some situations (e.g. demo app) we don't have any authentication.
# This will look a bit ugly... Will do for now.
config :magpie, :authentication,
  username: System.fetch_env!("AUTH_USERNAME"),
  password: System.fetch_env!("AUTH_PASSWORD")

config :magpie,
       :no_basic_auth,
       false

config :logger,
  backends: [:console]

# This is useful when the app is behind a reverse proxy and you need to actually use the URL shown to the outside by the reverse proxy, e.g. in template generation in web/templates/experiments/edit.html.eex
config :magpie, :real_url, System.get_env("REAL_URL", System.fetch_env!("HOST"))
