defmodule Magpie do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    if System.get_env("USE_TIMBER") == "true" do
      :ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})

      :ok =
        :telemetry.attach(
          "timber-ecto-query-handler",
          [:my_app, :repo, :query],
          &Timber.Ecto.handle_event/4,
          []
        )
    end

    # Create the directory to store the results
    File.mkdir("results/")

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      Magpie.Repo,
      # Start the endpoint when the application starts
      Magpie.Endpoint,
      # The presence supervisor
      Magpie.Presence,
      # Start your own worker by calling: Magpie.Worker.start_link(arg1, arg2, arg3)
      # worker(Magpie.Worker, [arg1, arg2, arg3]),
      worker(Task, [&Magpie.Experiments.reset_in_progress_experiment_statuses/0],
        restart: :temporary
      ),
      worker(Magpie.ChannelWatcher, [:participants])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Magpie.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Magpie.Endpoint.config_change(changed, removed)
    :ok
  end
end
