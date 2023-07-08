import Config

if System.get_env("PHX_SERVER") do
  config :magpie, MagpieWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :magpie, Magpie.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    # Allow clients from anywhere to connect to use the interactive experiment facilities. We can't constrain where the user chooses to host the frontend anyways.
    check_origin: false

  # Configure the database
  config :magpie, Magpie.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :logger,
    backends: [:console]

  # We don't have a basic auth on the demo app, so we need to allow for this flexibility
  config :magpie,
         :no_basic_auth,
         (if System.get_env("MAGPIE_NO_BASIC_AUTH") == "true" do
            true
          else
            false
          end)

  # Used for basic_auth
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
end
