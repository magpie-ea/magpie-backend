defmodule BABE.ExperimentStatus do
  @moduledoc """
  Keeps track of the experiment status, where it can be available/abandoned (0), in progress (1), or submitted (2). Especially useful for iterated experiments.
  """
  use BABE.Web, :model

  schema "experiment_statuses" do
    field(:variant, :integer, null: false)
    field(:chain, :integer, null: false)
    field(:realization, :integer, null: false)
    # 0 means not taken up/dropped. 1 means in progress. 2 means submitted
    field(:status, :integer, default: 0, null: false)

    belongs_to(:experiment, BABE.Experiment)

    timestamps(type: :utc_datetime)
  end

  def changeset(model, params \\ %{}) do
    model
    # `cast/3` ignores all parameters not explicitly permitted, converts all permitted key names into atoms, and store them in the :changes field of the changeset
    # The point is that only the :changes field will work when performing any real DB action with Repo.
    # This is to say, the other parameters are not "deleted" at this step yet. You can chain multiple `cast` calls.
    |> cast(params, [:experiment_id, :variant, :chain, :realization, :status])
    |> validate_required([:experiment_id, :variant, :chain, :realization, :status])
    # Must be associated with an experiment
    |> assoc_constraint(:experiment)
  end

  def multi_changeset_from_experiment(experiment) do
    # If the responsibility of the model module is only to create changesets then this should be a viable way to do it.
    # We should have a list of changesets after this.
      for variant <- 1..experiment.num_variants,
          chain <- 1..experiment.num_chains,
          realization <- 1..experiment.num_realizations do
        # Manually create maps for `Ecto.insert_all`
        %{
          experiment_id: experiment.id,
          variant: variant,
          chain: chain,
          realization: realization,
          status: 0,
          inserted_at: Ecto.DateTime.utc(),
          updated_at: Ecto.DateTime.utc()
        }
      end
  end
end
