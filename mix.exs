defmodule Magpie.Mixfile do
  use Mix.Project

  def project do
    [
      app: :magpie,
      version: "2.3.4",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      deps: deps()
    ]
  end

  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Magpie.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.2"},
      # phoenix_ecto 3.x corresponds to Ecto 2.x. phoenix_ecto 4.x corresponds to Ecto 3.x
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.18"},
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.2"},
      {:cors_plug, "~> 2.0"},
      # Temporary file download for experiment results
      {:briefly, "~> 0.3"},
      {:csv, "~> 2.4"},
      {:calendar, "~> 1.0"},
      {:wallaby, "~> 0.29.0", [runtime: false, only: :test]},
      {:excoveralls, "~> 0.14.2", only: :test},
      # Error checking and linting
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:dogma, "~> 0.1", only: [:dev]},
      # Frontend assets
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
