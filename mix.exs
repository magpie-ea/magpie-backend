defmodule BABE.Mixfile do
  use Mix.Project

  def project do
    [
      app: :babe,
      version: "0.2.3",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  @applications [
    :phoenix,
    :phoenix_pubsub,
    :phoenix_ecto,
    :phoenix_html,
    :gettext,
    :cowboy,
    :plug_cowboy,
    :poison,
    :jason,
    :cors_plug,
    :csv,
    :basic_auth,
    :calendar,
    :logger,
    :ecto_sql,
    :postgrex,
    :sentry
  ]

  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BABE, []},
      applications: @applications
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      # phoenix_ecto 3.x corresponds to Ecto 2.x. phoenix_ecto 4.x corresponds to Ecto 3.x
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:jason, "~> 1.1"},
      {:cors_plug, "~> 1.2"},
      {:csv, "~> 2.1"},
      {:basic_auth, "~> 2.2.2"},
      {:calendar, "~> 0.17.2"},
      {:distillery, "~> 2.0"},
      {:sentry, "~> 6.4"},
      {:wallaby, "~> 0.22.0", [runtime: false, only: :test]},
      # Error checking and linting
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dogma, "~> 0.1", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
