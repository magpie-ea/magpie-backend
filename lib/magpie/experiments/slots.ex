defmodule Magpie.Experiments.Slots do
  @moduledoc """
  Module for logic related to slots in experiments.
  """
  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment

  @doc """
  Since slot_ordering is an ordered list, we only need to find the first entry in the list which is available.
  """
  def get_next_free_slot(%Experiment{
        slot_ordering: slot_ordering,
        slot_statuses: slot_statuses,
        slot_dependencies: _slot_dependencies
      }) do
    Enum.reduce_while(slot_ordering, %{}, fn slot_name ->
      case Map.get(slot_statuses, slot_name) do
        "available" -> {:halt, slot_name}
        _ -> :cont
      end
    end)
  end

  @doc """
  Condition for freeing a slot:
  - This slot has condition "hold"
  - All dependencies of this slot has condition "done"

  Guess we'll need to go through all the slots for this check.

  Seems that the ordering might be irrelevant in this case.
  """
  def free_slots(
        %Experiment{
          slot_ordering: _slot_ordering,
          slot_statuses: orig_slot_statuses,
          slot_dependencies: _slot_dependencies
        } = experiment
      ) do
    # Do everything in one pass. Should be more efficient!
    new_slot_statuses =
      Enum.reduce(orig_slot_statuses, orig_slot_statuses, fn
        {slot_name, slot_status} ->
          if slot_status == "hold" && all_dependencies_done?(slot_name, experiment) do
            Map.put(orig_slot_statuses, slot_name, "available")
          else
            orig_slot_statuses
          end
      end)

    Experiments.update_experiment(experiment, slot_statuses: new_slot_statuses)
  end

  defp all_dependencies_done?(slot_name, %Experiment{
         slot_ordering: _slot_ordering,
         slot_statuses: slot_statuses,
         slot_dependencies: slot_dependencies
       }) do
    dependencies = Map.get(slot_dependencies, slot_name)
    Enum.all?(dependencies, fn dependency -> Map.get(slot_statuses, dependency) == "done" end)
  end

  def update_slot_status(
        %Experiment{
          slot_ordering: _slot_ordering,
          slot_statuses: orig_slot_statuses,
          slot_dependencies: _slot_dependencies
        } = experiment,
        slot_name,
        new_slot_status
      ) do
    new_slot_statuses = Map.put(orig_slot_statuses, slot_name, new_slot_status)
    Experiments.update_experiment(experiment, slot_statuses: new_slot_statuses)
  end

  def generate_slots_from_ulc_specification(%{
        num_variants: num_variants,
        num_chains: num_chains,
        num_generations: num_generations,
        num_players: num_players
      }) do
    # When we newly create the entries, we're always at the first copy of it all.
    copy_number = 1

    {slot_ordering, slot_statuses, slot_dependencies, slot_attempt_counts} =
      Enum.reduce(1..num_chains, {[], %{}, %{}, %{}}, fn chain, acc ->
        Enum.reduce(1..num_variants, acc, fn variant, acc ->
          Enum.reduce(1..num_generations, acc, fn generation, acc ->
            Enum.reduce(1..num_players, acc, fn player,
                                                {slot_ordering, slot_statuses, slot_dependencies,
                                                 slot_attempt_counts} ->
              slot_name = "#{copy_number}_#{chain}:#{variant}:#{generation}:#{player}"
              updated_slot_ordering = [slot_name | slot_ordering]
              updated_slot_statuses = Map.put(slot_statuses, slot_name, "hold")
              updated_slot_attempt_counts = Map.put(slot_attempt_counts, slot_name, 0)

              dependent_slots =
                if generation > 1 do
                  Enum.reduce(1..num_players, [], fn cur_player, acc ->
                    dependency_slot_name =
                      "#{copy_number}_#{chain}:#{variant}:#{generation - 1}:#{cur_player}"

                    [dependency_slot_name | acc]
                  end)
                else
                  []
                end

              updated_slot_dependencies = Map.put(slot_dependencies, slot_name, dependent_slots)

              {updated_slot_ordering, updated_slot_statuses, updated_slot_dependencies,
               updated_slot_attempt_counts}
            end)
          end)
        end)
      end)

    {Enum.reverse(slot_ordering), slot_statuses, slot_dependencies, slot_attempt_counts}
  end
end
