import Config

config :magpie, Magpie.Endpoint,
  http: [port: System.fetch_env!("PORT") |> String.to_integer()],
  url: [
    scheme: System.fetch_env!("URL_SCHEME"),
    host: System.fetch_env!("HOST"),
    path: System.fetch_env!("PATH"),
    port: System.fetch_env!("PORT") |> String.to_integer()
  ],
  force_ssl:
    (if System.fetch_env!("URL_SCHEME") == "https" do
       [rewrite_on: [:x_forwarded_proto]]
     else
       []
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
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  hostname: System.fetch_env!("DATABASE_HOST"),
  database: System.fetch_env!("DATABASE_NAME"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "2")),
  ssl: true,
  log:
    (if System.get_env("USE_TIMBER") == "true" do
       false
     else
       :debug
     end)

# Used for basic_auth
config :magpie, :authentication,
  username: System.fetch_env!("AUTH_USERNAME"),
  password: System.fetch_env!("AUTH_PASSWORD")

# We don't have a basic auth on the demo app
config :magpie,
       :no_basic_auth,
       (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
          true
        else
          false
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

# This is useful when the app is behind a reverse proxy and you need to actually use the URL shown to the outside by the reverse proxy, e.g. in template generation in web/templates/experiments/edit.html..ex
config :magpie, :real_url, System.get_env("REAL_URL", System.fetch_env!("HOST"))
