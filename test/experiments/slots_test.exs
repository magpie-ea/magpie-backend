defmodule Magpie.Experiments.SlotsTest do
  @moduledoc false

  use Magpie.ModelCase

  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment
  alias Magpie.Experiments.Slots

  describe "update_slots_from_ulc_specification/1" do
    test "correctly updates slot specs for the given Experiment" do
      slot_ordering = [
        "1_1:1:1:1",
        "1_1:1:1:2",
        "1_1:1:2:1",
        "1_1:1:2:2",
        "1_1:2:1:1",
        "1_1:2:1:2",
        "1_1:2:2:1",
        "1_1:2:2:2",
        "1_2:1:1:1",
        "1_2:1:1:2",
        "1_2:1:2:1",
        "1_2:1:2:2",
        "1_2:2:1:1",
        "1_2:2:1:2",
        "1_2:2:2:1",
        "1_2:2:2:2"
      ]

      slot_statuses = %{
        "1_1:1:1:1" => "hold",
        "1_1:1:1:2" => "hold",
        "1_1:1:2:1" => "hold",
        "1_1:1:2:2" => "hold",
        "1_1:2:1:1" => "hold",
        "1_1:2:1:2" => "hold",
        "1_1:2:2:1" => "hold",
        "1_1:2:2:2" => "hold",
        "1_2:1:1:1" => "hold",
        "1_2:1:1:2" => "hold",
        "1_2:1:2:1" => "hold",
        "1_2:1:2:2" => "hold",
        "1_2:2:1:1" => "hold",
        "1_2:2:1:2" => "hold",
        "1_2:2:2:1" => "hold",
        "1_2:2:2:2" => "hold"
      }

      slot_dependencies = %{
        "1_1:1:1:1" => [],
        "1_1:1:1:2" => [],
        "1_1:1:2:1" => ["1_1:1:1:2", "1_1:1:1:1"],
        "1_1:1:2:2" => ["1_1:1:1:2", "1_1:1:1:1"],
        "1_1:2:1:1" => [],
        "1_1:2:1:2" => [],
        "1_1:2:2:1" => ["1_1:2:1:2", "1_1:2:1:1"],
        "1_1:2:2:2" => ["1_1:2:1:2", "1_1:2:1:1"],
        "1_2:1:1:1" => [],
        "1_2:1:1:2" => [],
        "1_2:1:2:1" => ["1_2:1:1:2", "1_2:1:1:1"],
        "1_2:1:2:2" => ["1_2:1:1:2", "1_2:1:1:1"],
        "1_2:2:1:1" => [],
        "1_2:2:1:2" => [],
        "1_2:2:2:1" => ["1_2:2:1:2", "1_2:2:1:1"],
        "1_2:2:2:2" => ["1_2:2:1:2", "1_2:2:1:1"]
      }

      slot_attempt_counts = %{
        "1_1:1:1:1" => 0,
        "1_1:1:1:2" => 0,
        "1_1:1:2:1" => 0,
        "1_1:1:2:2" => 0,
        "1_1:2:1:1" => 0,
        "1_1:2:1:2" => 0,
        "1_1:2:2:1" => 0,
        "1_1:2:2:2" => 0,
        "1_2:1:1:1" => 0,
        "1_2:1:1:2" => 0,
        "1_2:1:2:1" => 0,
        "1_2:1:2:2" => 0,
        "1_2:2:1:1" => 0,
        "1_2:2:1:2" => 0,
        "1_2:2:2:1" => 0,
        "1_2:2:2:2" => 0
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          is_dynamic: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      Slots.update_slots_from_ulc_specification(experiment)

      assert %Experiment{
               slot_ordering: ^slot_ordering,
               slot_statuses: ^slot_statuses,
               slot_dependencies: ^slot_dependencies,
               slot_attempt_counts: ^slot_attempt_counts
             } = Experiments.get_experiment!(experiment.id)
    end
  end
end
