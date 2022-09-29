defmodule Magpie.Experiments.SlotsTest do
  @moduledoc false

  use Magpie.ModelCase

  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment
  alias Magpie.Experiments.Slots

  describe "initialize_or_update_slots_from_ulc_specification/1" do
    test "correctly initializes slot specs for the given Experiment and frees the slots" do
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
              }} = Slots.initialize_or_update_slots_from_ulc_specification(experiment)
    end

    test "expands the slots correctly for the given Experiment by incrementing the copy count" do
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
        "2_1:1:1_1" => "hold",
        "2_1:1:1_2" => "hold",
        "2_1:1:2_1" => "hold",
        "2_1:1:2_2" => "hold",
        "2_1:2:1_1" => "hold",
        "2_1:2:1_2" => "hold",
        "2_1:2:2_1" => "hold",
        "2_1:2:2_2" => "hold",
        "2_2:1:1_1" => "hold",
        "2_2:1:1_2" => "hold",
        "2_2:1:2_1" => "hold",
        "2_2:1:2_2" => "hold",
        "2_2:2:1_1" => "hold",
        "2_2:2:1_2" => "hold",
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
        "2_1:1:1_1" => 0,
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

      {:ok, updated_experiment} =
        Slots.initialize_or_update_slots_from_ulc_specification(experiment)

      assert updated_experiment.slot_ordering == expected_slot_ordering
      assert updated_experiment.slot_statuses == expected_slot_statuses
      assert updated_experiment.slot_dependencies == expected_slot_dependencies
      assert updated_experiment.slot_attempt_counts == expected_slot_attempt_counts
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

      {:ok, experiment} = Slots.initialize_or_update_slots_from_ulc_specification(experiment)

      # 8 in total freed.
      # assert {{:ok, %Experiment{slot_statuses: ^expected_slot_statuses}}, 8} =
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

      # 8 in total freed.
      # assert {{:ok, %Experiment{slot_statuses: ^expected_slot_statuses}}, 8} =
      assert {:ok, %Experiment{slot_statuses: ^expected_slot_statuses}} =
               Slots.free_slots(experiment)
    end
  end

  describe "get_all_available_slots/1" do
    test "returns all available slots in the correct order" do
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

      assert [
               "1_1:1:2_1",
               "1_1:1:2_2",
               "1_1:2:2_1",
               "1_1:2:2_2",
               "1_2:1:2_1",
               "1_2:1:2_2",
               "1_2:2:2_1",
               "1_2:2:2_2"
             ] == Slots.get_all_available_slots(experiment)
    end

    test "expands the slots and frees them before returning the available ones, if there are no available slots" do
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

      assert [
               "2_1:1:1_1",
               "2_1:1:1_2",
               "2_1:2:1_1",
               "2_1:2:1_2",
               "2_2:1:1_1",
               "2_2:1:1_2",
               "2_2:2:1_1",
               "2_2:2:1_2"
             ] == Slots.get_all_available_slots(experiment)
    end
  end
end
