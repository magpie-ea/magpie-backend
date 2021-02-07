import Config

config :magpie, Magpie.Endpoint,
  http: [port: System.get_env("PORT", "443") |> String.to_integer()],
  url: [
    scheme: System.get_env("URL_SCHEME", "https"),
    host: System.fetch_env!("HOST"),
    path: System.get_env("MAGPIE_PATH", "/"),
    port: System.get_env("PORT", "443") |> String.to_integer()
  ],
  # Don't use force_ssl if the URL_SCHEME is http
  force_ssl:
    (if System.get_env("URL_SCHEME") == "http" do
       []
     else
       [rewrite_on: [:x_forwarded_proto]]
     end),
  server: true,
  # Allow clients from anywhere to connect to use the interactive experiment facilities. We can't constrain where the user chooses to host the frontend anyways.
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  check_origin: false,
  root: ".",
  version: Application.spec(:magpie, :vsn),
  instrumenters:
    (if System.get_env("USE_TIMBER") == "true" do
       [Timber.Phoenix]
     else
       []
     end)

# Configure the database
config :magpie, Magpie.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "2")),
  ssl: true,
  log:
    (if System.get_env("USE_TIMBER") == "true" do
       false
     else
       :debug
    end)

# Used for basic_auth
# However, we can't assume they always exist, since in some situations (e.g. demo app) we don't have any authentication.
# This will look a bit ugly... Will do for now.
config :magpie, :authentication,
  username:
    (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
       nil
     else
       System.fetch_env!("AUTH_USERNAME")
     end),
  password:
    (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
       nil
     else
       System.fetch_env!("AUTH_PASSWORD")
     end)

config :logger,
  backends:
    (if System.get_env("USE_TIMBER") == "true" do
       [Timber.LoggerBackends.HTTP, :console]
     else
       [:console]
     end)

# Logging
config :timber,
  api_key: System.get_env("TIMBER_API_KEY"),
  source_id: System.get_env("TIMBER_SOURCE_ID")

# This is useful when the app is behind a reverse proxy and you need to actually use the URL shown to the outside by the reverse proxy, e.g. in template generation in web/templates/experiments/edit.html.eex
config :magpie, :real_url, System.get_env("REAL_URL", System.fetch_env!("HOST"))
