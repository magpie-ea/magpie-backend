defmodule Magpie.Experiments.SlotsTest do
  @moduledoc false

  use Magpie.ModelCase

  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment
  alias Magpie.Experiments.Slots

  defp experiment_fixture() do
    {:ok, experiment} =
      Experiments.create_experiment(%{
        name: "some name",
        author: "some author",
        description: "some description",
        active: true,
        num_variants: 2,
        num_chains: 2,
        num_generations: 2,
        num_players: 2
      })

    experiment
  end

  describe "initialize_slots_from_ulc_specification/1" do
    test "correctly initializes slot specs for the given Experiment" do
      slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2",
        "1_1:1:2_1",
        "1_1:1:2_2",
        "1_1:2:1_1",
        "1_1:2:1_2",
        "1_1:2:2_1",
        "1_1:2:2_2",
        "1_2:1:1_1",
        "1_2:1:1_2",
        "1_2:1:2_1",
        "1_2:1:2_2",
        "1_2:2:1_1",
        "1_2:2:1_2",
        "1_2:2:2_1",
        "1_2:2:2_2"
      ]

      slot_statuses = %{
        "1_1:1:1_1" => "hold",
        "1_1:1:1_2" => "hold",
        "1_1:1:2_1" => "hold",
        "1_1:1:2_2" => "hold",
        "1_1:2:1_1" => "hold",
        "1_1:2:1_2" => "hold",
        "1_1:2:2_1" => "hold",
        "1_1:2:2_2" => "hold",
        "1_2:1:1_1" => "hold",
        "1_2:1:1_2" => "hold",
        "1_2:1:2_1" => "hold",
        "1_2:1:2_2" => "hold",
        "1_2:2:1_1" => "hold",
        "1_2:2:1_2" => "hold",
        "1_2:2:2_1" => "hold",
        "1_2:2:2_2" => "hold"
      }

      trial_players = %{
        "1_1:1:1_1" => 2,
        "1_1:1:1_2" => 2,
        "1_1:1:2_1" => 2,
        "1_1:1:2_2" => 2,
        "1_1:2:1_1" => 2,
        "1_1:2:1_2" => 2,
        "1_1:2:2_1" => 2,
        "1_1:2:2_2" => 2,
        "1_2:1:1_1" => 2,
        "1_2:1:1_2" => 2,
        "1_2:1:2_1" => 2,
        "1_2:1:2_2" => 2,
        "1_2:2:1_1" => 2,
        "1_2:2:1_2" => 2,
        "1_2:2:2_1" => 2,
        "1_2:2:2_2" => 2
      }

      slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => [],
        "1_1:1:2_1" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:1:2_2" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:2:1_1" => [],
        "1_1:2:1_2" => [],
        "1_1:2:2_1" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_1:2:2_2" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_2:1:1_1" => [],
        "1_2:1:1_2" => [],
        "1_2:1:2_1" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:1:2_2" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:2:1_1" => [],
        "1_2:2:1_2" => [],
        "1_2:2:2_1" => ["1_2:2:1_2", "1_2:2:1_1"],
        "1_2:2:2_2" => ["1_2:2:1_2", "1_2:2:1_1"]
      }

      slot_attempt_counts = %{
        "1_1:1:1_1" => 0,
        "1_1:1:1_2" => 0,
        "1_1:1:2_1" => 0,
        "1_1:1:2_2" => 0,
        "1_1:2:1_1" => 0,
        "1_1:2:1_2" => 0,
        "1_1:2:2_1" => 0,
        "1_1:2:2_2" => 0,
        "1_2:1:1_1" => 0,
        "1_2:1:1_2" => 0,
        "1_2:1:2_1" => 0,
        "1_2:1:2_2" => 0,
        "1_2:2:1_1" => 0,
        "1_2:2:1_2" => 0,
        "1_2:2:2_1" => 0,
        "1_2:2:2_2" => 0
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      assert {:ok,
              %Experiment{
                slot_ordering: ^slot_ordering,
                slot_statuses: ^slot_statuses,
                slot_dependencies: ^slot_dependencies,
                slot_attempt_counts: ^slot_attempt_counts,
                trial_players: ^trial_players,
                copy_number: 1
              }} = Slots.initialize_slots_from_ulc_specification(experiment)
    end
  end

  describe "free_slots/1" do
    test "correctly free slots from initial ULC state" do
      expected_slot_statuses = %{
        "1_1:1:1_1" => "available",
        "1_1:1:1_2" => "available",
        "1_1:1:2_1" => "hold",
        "1_1:1:2_2" => "hold",
        "1_1:2:1_1" => "available",
        "1_1:2:1_2" => "available",
        "1_1:2:2_1" => "hold",
        "1_1:2:2_2" => "hold",
        "1_2:1:1_1" => "available",
        "1_2:1:1_2" => "available",
        "1_2:1:2_1" => "hold",
        "1_2:1:2_2" => "hold",
        "1_2:2:1_1" => "available",
        "1_2:2:1_2" => "available",
        "1_2:2:2_1" => "hold",
        "1_2:2:2_2" => "hold"
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      {:ok, experiment} = Slots.initialize_slots_from_ulc_specification(experiment)

      assert {:ok, %Experiment{slot_statuses: ^expected_slot_statuses}} =
               Slots.free_slots(experiment)
    end

    test "correctly free slots based on slot_dependencies" do
      slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2",
        "1_1:1:2_1",
        "1_1:1:2_2",
        "1_1:2:1_1",
        "1_1:2:1_2",
        "1_1:2:2_1",
        "1_1:2:2_2",
        "1_2:1:1_1",
        "1_2:1:1_2",
        "1_2:1:2_1",
        "1_2:1:2_2",
        "1_2:2:1_1",
        "1_2:2:1_2",
        "1_2:2:2_1",
        "1_2:2:2_2"
      ]

      starting_slot_statuses = %{
        "1_1:1:1_1" => "done",
        "1_1:1:1_2" => "done",
        "1_1:1:2_1" => "hold",
        "1_1:1:2_2" => "hold",
        "1_1:2:1_1" => "done",
        "1_1:2:1_2" => "done",
        "1_1:2:2_1" => "hold",
        "1_1:2:2_2" => "hold",
        "1_2:1:1_1" => "done",
        "1_2:1:1_2" => "done",
        "1_2:1:2_1" => "hold",
        "1_2:1:2_2" => "hold",
        "1_2:2:1_1" => "done",
        "1_2:2:1_2" => "done",
        "1_2:2:2_1" => "hold",
        "1_2:2:2_2" => "hold"
      }

      slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => [],
        "1_1:1:2_1" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:1:2_2" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:2:1_1" => [],
        "1_1:2:1_2" => [],
        "1_1:2:2_1" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_1:2:2_2" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_2:1:1_1" => [],
        "1_2:1:1_2" => [],
        "1_2:1:2_1" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:1:2_2" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:2:1_1" => [],
        "1_2:2:1_2" => [],
        "1_2:2:2_1" => ["1_2:2:1_2", "1_2:2:1_1"],
        "1_2:2:2_2" => ["1_2:2:1_2", "1_2:2:1_1"]
      }

      starting_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_1:1:1_2" => 1,
        "1_1:1:2_1" => 0,
        "1_1:1:2_2" => 0,
        "1_1:2:1_1" => 1,
        "1_1:2:1_2" => 1,
        "1_1:2:2_1" => 0,
        "1_1:2:2_2" => 0,
        "1_2:1:1_1" => 1,
        "1_2:1:1_2" => 1,
        "1_2:1:2_1" => 0,
        "1_2:1:2_2" => 0,
        "1_2:2:1_1" => 1,
        "1_2:2:1_2" => 1,
        "1_2:2:2_1" => 0,
        "1_2:2:2_2" => 0
      }

      expected_slot_statuses = %{
        "1_1:1:1_1" => "done",
        "1_1:1:1_2" => "done",
        "1_1:1:2_1" => "available",
        "1_1:1:2_2" => "available",
        "1_1:2:1_1" => "done",
        "1_1:2:1_2" => "done",
        "1_1:2:2_1" => "available",
        "1_1:2:2_2" => "available",
        "1_2:1:1_1" => "done",
        "1_2:1:1_2" => "done",
        "1_2:1:2_1" => "available",
        "1_2:1:2_2" => "available",
        "1_2:2:1_1" => "done",
        "1_2:2:1_2" => "done",
        "1_2:2:2_1" => "available",
        "1_2:2:2_2" => "available"
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      {:ok, experiment} =
        Experiments.update_experiment(
          experiment,
          %{
            slot_statuses: starting_slot_statuses,
            slot_ordering: slot_ordering,
            slot_dependencies: slot_dependencies,
            slot_attempt_counts: starting_slot_attempt_counts
          }
        )

      assert {:ok, %Experiment{slot_statuses: ^expected_slot_statuses}} =
               Slots.free_slots(experiment)
    end
  end

  describe "get_and_set_to_in_progress_next_free_slot/1" do
    test "get and set the status of the next free slot according to slot_ordering" do
      expected_slot_statuses = %{
        "1_1:1:1_1" => "in_progress",
        "1_1:1:1_2" => "available",
        "1_1:1:2_1" => "hold",
        "1_1:1:2_2" => "hold",
        "1_1:2:1_1" => "available",
        "1_1:2:1_2" => "available",
        "1_1:2:2_1" => "hold",
        "1_1:2:2_2" => "hold",
        "1_2:1:1_1" => "available",
        "1_2:1:1_2" => "available",
        "1_2:1:2_1" => "hold",
        "1_2:1:2_2" => "hold",
        "1_2:2:1_1" => "available",
        "1_2:2:1_2" => "available",
        "1_2:2:2_1" => "hold",
        "1_2:2:2_2" => "hold"
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      {:ok, updated_experiment} = Slots.initialize_slots_from_ulc_specification(experiment)

      assert {:ok, "1_1:1:1_1"} ==
               Slots.get_and_set_to_in_progress_next_free_slot(updated_experiment)

      assert %Experiment{
               slot_statuses: ^expected_slot_statuses
             } = Experiments.get_experiment!(experiment.id)
    end

    test "expands the slots correctly" do
      starting_slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2",
        "1_1:1:2_1",
        "1_1:1:2_2",
        "1_1:2:1_1",
        "1_1:2:1_2",
        "1_1:2:2_1",
        "1_1:2:2_2",
        "1_2:1:1_1",
        "1_2:1:1_2",
        "1_2:1:2_1",
        "1_2:1:2_2",
        "1_2:2:1_1",
        "1_2:2:1_2",
        "1_2:2:2_1",
        "1_2:2:2_2"
      ]

      starting_slot_statuses = %{
        "1_1:1:1_1" => "done",
        "1_1:1:1_2" => "done",
        "1_1:1:2_1" => "done",
        "1_1:1:2_2" => "done",
        "1_1:2:1_1" => "done",
        "1_1:2:1_2" => "done",
        "1_1:2:2_1" => "done",
        "1_1:2:2_2" => "done",
        "1_2:1:1_1" => "done",
        "1_2:1:1_2" => "done",
        "1_2:1:2_1" => "done",
        "1_2:1:2_2" => "done",
        "1_2:2:1_1" => "done",
        "1_2:2:1_2" => "done",
        "1_2:2:2_1" => "done",
        "1_2:2:2_2" => "done"
      }

      starting_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => [],
        "1_1:1:2_1" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:1:2_2" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:2:1_1" => [],
        "1_1:2:1_2" => [],
        "1_1:2:2_1" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_1:2:2_2" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_2:1:1_1" => [],
        "1_2:1:1_2" => [],
        "1_2:1:2_1" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:1:2_2" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:2:1_1" => [],
        "1_2:2:1_2" => [],
        "1_2:2:2_1" => ["1_2:2:1_2", "1_2:2:1_1"],
        "1_2:2:2_2" => ["1_2:2:1_2", "1_2:2:1_1"]
      }

      starting_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_1:1:1_2" => 1,
        "1_1:1:2_1" => 1,
        "1_1:1:2_2" => 1,
        "1_1:2:1_1" => 1,
        "1_1:2:1_2" => 1,
        "1_1:2:2_1" => 1,
        "1_1:2:2_2" => 1,
        "1_2:1:1_1" => 1,
        "1_2:1:1_2" => 1,
        "1_2:1:2_1" => 1,
        "1_2:1:2_2" => 1,
        "1_2:2:1_1" => 1,
        "1_2:2:1_2" => 1,
        "1_2:2:2_1" => 1,
        "1_2:2:2_2" => 1
      }

      expected_slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2",
        "1_1:1:2_1",
        "1_1:1:2_2",
        "1_1:2:1_1",
        "1_1:2:1_2",
        "1_1:2:2_1",
        "1_1:2:2_2",
        "1_2:1:1_1",
        "1_2:1:1_2",
        "1_2:1:2_1",
        "1_2:1:2_2",
        "1_2:2:1_1",
        "1_2:2:1_2",
        "1_2:2:2_1",
        "1_2:2:2_2",
        "2_1:1:1_1",
        "2_1:1:1_2",
        "2_1:1:2_1",
        "2_1:1:2_2",
        "2_1:2:1_1",
        "2_1:2:1_2",
        "2_1:2:2_1",
        "2_1:2:2_2",
        "2_2:1:1_1",
        "2_2:1:1_2",
        "2_2:1:2_1",
        "2_2:1:2_2",
        "2_2:2:1_1",
        "2_2:2:1_2",
        "2_2:2:2_1",
        "2_2:2:2_2"
      ]

      expected_slot_statuses = %{
        "1_1:1:1_1" => "done",
        "1_1:1:1_2" => "done",
        "1_1:1:2_1" => "done",
        "1_1:1:2_2" => "done",
        "1_1:2:1_1" => "done",
        "1_1:2:1_2" => "done",
        "1_1:2:2_1" => "done",
        "1_1:2:2_2" => "done",
        "1_2:1:1_1" => "done",
        "1_2:1:1_2" => "done",
        "1_2:1:2_1" => "done",
        "1_2:1:2_2" => "done",
        "1_2:2:1_1" => "done",
        "1_2:2:1_2" => "done",
        "1_2:2:2_1" => "done",
        "1_2:2:2_2" => "done",
        "2_1:1:1_1" => "in_progress",
        "2_1:1:1_2" => "available",
        "2_1:1:2_1" => "hold",
        "2_1:1:2_2" => "hold",
        "2_1:2:1_1" => "available",
        "2_1:2:1_2" => "available",
        "2_1:2:2_1" => "hold",
        "2_1:2:2_2" => "hold",
        "2_2:1:1_1" => "available",
        "2_2:1:1_2" => "available",
        "2_2:1:2_1" => "hold",
        "2_2:1:2_2" => "hold",
        "2_2:2:1_1" => "available",
        "2_2:2:1_2" => "available",
        "2_2:2:2_1" => "hold",
        "2_2:2:2_2" => "hold"
      }

      expected_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => [],
        "1_1:1:2_1" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:1:2_2" => ["1_1:1:1_2", "1_1:1:1_1"],
        "1_1:2:1_1" => [],
        "1_1:2:1_2" => [],
        "1_1:2:2_1" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_1:2:2_2" => ["1_1:2:1_2", "1_1:2:1_1"],
        "1_2:1:1_1" => [],
        "1_2:1:1_2" => [],
        "1_2:1:2_1" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:1:2_2" => ["1_2:1:1_2", "1_2:1:1_1"],
        "1_2:2:1_1" => [],
        "1_2:2:1_2" => [],
        "1_2:2:2_1" => ["1_2:2:1_2", "1_2:2:1_1"],
        "1_2:2:2_2" => ["1_2:2:1_2", "1_2:2:1_1"],
        "2_1:1:1_1" => [],
        "2_1:1:1_2" => [],
        "2_1:1:2_1" => ["2_1:1:1_2", "2_1:1:1_1"],
        "2_1:1:2_2" => ["2_1:1:1_2", "2_1:1:1_1"],
        "2_1:2:1_1" => [],
        "2_1:2:1_2" => [],
        "2_1:2:2_1" => ["2_1:2:1_2", "2_1:2:1_1"],
        "2_1:2:2_2" => ["2_1:2:1_2", "2_1:2:1_1"],
        "2_2:1:1_1" => [],
        "2_2:1:1_2" => [],
        "2_2:1:2_1" => ["2_2:1:1_2", "2_2:1:1_1"],
        "2_2:1:2_2" => ["2_2:1:1_2", "2_2:1:1_1"],
        "2_2:2:1_1" => [],
        "2_2:2:1_2" => [],
        "2_2:2:2_1" => ["2_2:2:1_2", "2_2:2:1_1"],
        "2_2:2:2_2" => ["2_2:2:1_2", "2_2:2:1_1"]
      }

      expected_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_1:1:1_2" => 1,
        "1_1:1:2_1" => 1,
        "1_1:1:2_2" => 1,
        "1_1:2:1_1" => 1,
        "1_1:2:1_2" => 1,
        "1_1:2:2_1" => 1,
        "1_1:2:2_2" => 1,
        "1_2:1:1_1" => 1,
        "1_2:1:1_2" => 1,
        "1_2:1:2_1" => 1,
        "1_2:1:2_2" => 1,
        "1_2:2:1_1" => 1,
        "1_2:2:1_2" => 1,
        "1_2:2:2_1" => 1,
        "1_2:2:2_2" => 1,
        "2_1:1:1_1" => 1,
        "2_1:1:1_2" => 0,
        "2_1:1:2_1" => 0,
        "2_1:1:2_2" => 0,
        "2_1:2:1_1" => 0,
        "2_1:2:1_2" => 0,
        "2_1:2:2_1" => 0,
        "2_1:2:2_2" => 0,
        "2_2:1:1_1" => 0,
        "2_2:1:1_2" => 0,
        "2_2:1:2_1" => 0,
        "2_2:1:2_2" => 0,
        "2_2:2:1_1" => 0,
        "2_2:2:1_2" => 0,
        "2_2:2:2_1" => 0,
        "2_2:2:2_2" => 0
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 2,
          num_chains: 2,
          num_generations: 2,
          num_players: 2
        })

      {:ok, experiment} =
        Experiments.update_experiment(
          experiment,
          %{
            slot_statuses: starting_slot_statuses,
            slot_ordering: starting_slot_ordering,
            slot_dependencies: starting_slot_dependencies,
            slot_attempt_counts: starting_slot_attempt_counts,
            copy_number: 1
          }
        )

      assert {:ok, "2_1:1:1_1"} == Slots.get_and_set_to_in_progress_next_free_slot(experiment)

      assert %Experiment{
               slot_ordering: ^expected_slot_ordering,
               slot_statuses: ^expected_slot_statuses,
               slot_dependencies: ^expected_slot_dependencies,
               slot_attempt_counts: ^expected_slot_attempt_counts
             } = Experiments.get_experiment!(experiment.id)
    end

    test "expands the slots correctly for interactive-only experiments" do
      starting_slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2"
      ]

      starting_slot_statuses = %{
        "1_1:1:1_1" => "in_progress",
        "1_1:1:1_2" => "in_progress"
      }

      starting_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => []
      }

      starting_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_1:1:1_2" => 1
      }

      expected_slot_ordering = [
        "1_1:1:1_1",
        "1_1:1:1_2",
        "2_1:1:1_1",
        "2_1:1:1_2"
      ]

      expected_slot_statuses = %{
        "1_1:1:1_1" => "in_progress",
        "1_1:1:1_2" => "in_progress",
        "2_1:1:1_1" => "in_progress",
        "2_1:1:1_2" => "available"
      }

      expected_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_1:1:1_2" => [],
        "2_1:1:1_1" => [],
        "2_1:1:1_2" => []
      }

      expected_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_1:1:1_2" => 1,
        "2_1:1:1_1" => 1,
        "2_1:1:1_2" => 0
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 1,
          num_chains: 1,
          num_generations: 1,
          num_players: 2
        })

      {:ok, experiment} =
        Experiments.update_experiment(
          experiment,
          %{
            slot_statuses: starting_slot_statuses,
            slot_ordering: starting_slot_ordering,
            slot_dependencies: starting_slot_dependencies,
            slot_attempt_counts: starting_slot_attempt_counts,
            copy_number: 1
          }
        )

      assert {:ok, "2_1:1:1_1"} == Slots.get_and_set_to_in_progress_next_free_slot(experiment)

      assert %Experiment{
               slot_ordering: ^expected_slot_ordering,
               slot_statuses: ^expected_slot_statuses,
               slot_dependencies: ^expected_slot_dependencies,
               slot_attempt_counts: ^expected_slot_attempt_counts
             } = Experiments.get_experiment!(experiment.id)
    end

    test "expands the slots correctly for plain experiments" do
      starting_slot_ordering = [
        "1_1:1:1_1",
        "1_2:1:1_1",
        "1_3:1:1_1",
        "1_4:1:1_1",
        "1_5:1:1_1",
        "1_6:1:1_1",
        "1_7:1:1_1",
        "1_8:1:1_1",
        "1_9:1:1_1",
        "1_10:1:1_1"
      ]

      starting_slot_statuses = %{
        "1_1:1:1_1" => "in_progress",
        "1_2:1:1_1" => "in_progress",
        "1_3:1:1_1" => "in_progress",
        "1_4:1:1_1" => "in_progress",
        "1_5:1:1_1" => "in_progress",
        "1_6:1:1_1" => "in_progress",
        "1_7:1:1_1" => "in_progress",
        "1_8:1:1_1" => "in_progress",
        "1_9:1:1_1" => "in_progress",
        "1_10:1:1_1" => "in_progress"
      }

      starting_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_2:1:1_1" => [],
        "1_3:1:1_1" => [],
        "1_4:1:1_1" => [],
        "1_5:1:1_1" => [],
        "1_6:1:1_1" => [],
        "1_7:1:1_1" => [],
        "1_8:1:1_1" => [],
        "1_9:1:1_1" => [],
        "1_10:1:1_1" => []
      }

      starting_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_2:1:1_1" => 1,
        "1_3:1:1_1" => 1,
        "1_4:1:1_1" => 1,
        "1_5:1:1_1" => 1,
        "1_6:1:1_1" => 1,
        "1_7:1:1_1" => 1,
        "1_8:1:1_1" => 1,
        "1_9:1:1_1" => 1,
        "1_10:1:1_1" => 1
      }

      expected_slot_ordering = [
        "1_1:1:1_1",
        "1_2:1:1_1",
        "1_3:1:1_1",
        "1_4:1:1_1",
        "1_5:1:1_1",
        "1_6:1:1_1",
        "1_7:1:1_1",
        "1_8:1:1_1",
        "1_9:1:1_1",
        "1_10:1:1_1",
        "2_1:1:1_1",
        "2_2:1:1_1",
        "2_3:1:1_1",
        "2_4:1:1_1",
        "2_5:1:1_1",
        "2_6:1:1_1",
        "2_7:1:1_1",
        "2_8:1:1_1",
        "2_9:1:1_1",
        "2_10:1:1_1"
      ]

      expected_slot_statuses = %{
        "1_1:1:1_1" => "in_progress",
        "1_2:1:1_1" => "in_progress",
        "1_3:1:1_1" => "in_progress",
        "1_4:1:1_1" => "in_progress",
        "1_5:1:1_1" => "in_progress",
        "1_6:1:1_1" => "in_progress",
        "1_7:1:1_1" => "in_progress",
        "1_8:1:1_1" => "in_progress",
        "1_9:1:1_1" => "in_progress",
        "1_10:1:1_1" => "in_progress",
        "2_1:1:1_1" => "in_progress",
        "2_2:1:1_1" => "available",
        "2_3:1:1_1" => "available",
        "2_4:1:1_1" => "available",
        "2_5:1:1_1" => "available",
        "2_6:1:1_1" => "available",
        "2_7:1:1_1" => "available",
        "2_8:1:1_1" => "available",
        "2_9:1:1_1" => "available",
        "2_10:1:1_1" => "available"
      }

      expected_slot_dependencies = %{
        "1_1:1:1_1" => [],
        "1_2:1:1_1" => [],
        "1_3:1:1_1" => [],
        "1_4:1:1_1" => [],
        "1_5:1:1_1" => [],
        "1_6:1:1_1" => [],
        "1_7:1:1_1" => [],
        "1_8:1:1_1" => [],
        "1_9:1:1_1" => [],
        "1_10:1:1_1" => [],
        "2_1:1:1_1" => [],
        "2_2:1:1_1" => [],
        "2_3:1:1_1" => [],
        "2_4:1:1_1" => [],
        "2_5:1:1_1" => [],
        "2_6:1:1_1" => [],
        "2_7:1:1_1" => [],
        "2_8:1:1_1" => [],
        "2_9:1:1_1" => [],
        "2_10:1:1_1" => []
      }

      expected_slot_attempt_counts = %{
        "1_1:1:1_1" => 1,
        "1_2:1:1_1" => 1,
        "1_3:1:1_1" => 1,
        "1_4:1:1_1" => 1,
        "1_5:1:1_1" => 1,
        "1_6:1:1_1" => 1,
        "1_7:1:1_1" => 1,
        "1_8:1:1_1" => 1,
        "1_9:1:1_1" => 1,
        "1_10:1:1_1" => 1,
        "2_1:1:1_1" => 1,
        "2_2:1:1_1" => 0,
        "2_3:1:1_1" => 0,
        "2_4:1:1_1" => 0,
        "2_5:1:1_1" => 0,
        "2_6:1:1_1" => 0,
        "2_7:1:1_1" => 0,
        "2_8:1:1_1" => 0,
        "2_9:1:1_1" => 0,
        "2_10:1:1_1" => 0
      }

      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "some name",
          author: "some author",
          description: "some description",
          active: true,
          num_variants: 1,
          num_chains: 10,
          num_generations: 1,
          num_players: 1
        })

      {:ok, experiment} =
        Experiments.update_experiment(
          experiment,
          %{
            slot_statuses: starting_slot_statuses,
            slot_ordering: starting_slot_ordering,
            slot_dependencies: starting_slot_dependencies,
            slot_attempt_counts: starting_slot_attempt_counts,
            copy_number: 1
          }
        )

      assert {:ok, "2_1:1:1_1"} == Slots.get_and_set_to_in_progress_next_free_slot(experiment)

      assert %Experiment{
               slot_ordering: ^expected_slot_ordering,
               slot_statuses: ^expected_slot_statuses,
               slot_dependencies: ^expected_slot_dependencies,
               slot_attempt_counts: ^expected_slot_attempt_counts
             } = Experiments.get_experiment!(experiment.id)
    end
  end
end
