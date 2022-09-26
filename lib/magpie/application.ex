defmodule Magpie.Application do
  @moduledoc false
  use Application

  alias Magpie.Repo

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Create the directory to store the results
    File.mkdir("results/")

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      Magpie.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, [name: Magpie.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start the endpoint when the application starts
      Magpie.Endpoint,
      # The presence supervisor
      Magpie.Presence,
      # Start your own worker by calling: Magpie.Worker.start_link(arg1, arg2, arg3)
      # worker(Magpie.Worker, [arg1, arg2, arg3]),
      # Starts a worker by calling: Magpie.Worker.start_link(arg)
      # {Magpie.Worker, arg},
      # {Magpie.Experiments.ExperimentStatusResetWorker, []},

      # Registry for keeping track of the workers.
      {Registry, keys: :unique, name: Magpie.Registry},
      # DynamicSupervisor to supervise the workers.
      {DynamicSupervisor, strategy: :one_for_one, name: Magpie.DynamicSupervisor},
      {Magpie.Experiments.ChannelWatcher, :participants}
      # {Magpie.Experiments.WaitingQueueWorker, []}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Magpie.Supervisor]
    result = Supervisor.start_link(children, opts)

    # I can also just start all the workers under the dynamic supervisor here.
    experiments = Magpie.Repo.all(Magpie.Experiments.Experiment)

    Enum.each(experiments, fn experiment ->
      DynamicSupervisor.start_child(
        Magpie.DynamicSupervisor,
        {Magpie.Experiments.AssignExperimentSlotsWorker, experiment.id}
      )

      DynamicSupervisor.start_child(
        Magpie.DynamicSupervisor,
        {Magpie.Experiments.WaitingQueueWorker, experiment.id}
      )
    end)

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Magpie.Endpoint.config_change(changed, removed)
    :ok
  end
end
