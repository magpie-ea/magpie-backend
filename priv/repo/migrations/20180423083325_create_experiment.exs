# This is the creation of the true "Experiment" table used to manage experiments now
defmodule ProComPrag.Repo.Migrations.CreateExperiment do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :experiment_id, :string
      add :author, :string
      add :description, :text
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:experiments, [:experiment_id])
    create index(:experiments, [:author])

    # Dubious if I actually need to create foreign keys at all... It will always be a join operation for the lookup anyways right? Foreign key is a constraint relationship. But if we can explicitly match against the experiment_id and author fields, which are present in both tables, I don't think we need this automatic constraint thing.

    # Of course, the alternative would be to NOT store the experiment_id and author in the experiment_results table at all, which seems actually neater. Unfortunately we already have the previous DB up and running, and it would be a pain to refactor the data from now on, as always... Eh, the pain of DB maintenance

    # alter table(:experiment_results) do
    #   modify :experiment_id, references("experiments")
    #   modify :author, references("experiments")
    #   # Dubious if I still need :description to be a foreign key. That really is something optional.
    # end

    # I can add a foreign key on the surrogate PK of the "experiments" table though I'm not sure if that'll be very useful. Let me leave it for later and for now proceed with controllers.
  end
end
