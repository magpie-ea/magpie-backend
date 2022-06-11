defmodule Magpie.Experiments.Slots do
  @moduledoc """
  Module for logic related to slots in experiments.
  """
  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment

  @doc """
  Since slot_ordering is an ordered list, we only need to find the first entry in the list which is available.

  Note that we'll need to perform an expansion in the situation where the slots are all exhausted.

  Need to call these functions in a transaction. Otherwise some other process might try to call free_slots and expand_experiment at the same time.
  """
  def get_next_free_slot(%Experiment{} = experiment) do
    # Actually, we may need to always call `free_slots/1` at the beginning of this function call. Let's see.
    {:ok, %Experiment{slot_ordering: slot_ordering, slot_statuses: slot_statuses} = experiment} =
      free_slots(experiment)

    next_slot =
      Enum.find(slot_ordering, fn slot_name ->
        Map.get(slot_statuses, slot_name) == "available"
      end)

    case next_slot do
      nil ->
        {:ok, expanded_experiment} = expand_experiment(experiment)
        get_next_free_slot(expanded_experiment)

      _ ->
        next_slot
    end
  end

  defp expand_experiment(%Experiment{is_ulc: true} = experiment) do
    update_slots_from_ulc_specification(experiment)
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
        {slot_name, slot_status}, orig_slot_statuses ->
          if slot_status == "hold" && all_dependencies_done?(slot_name, experiment) do
            Map.put(orig_slot_statuses, slot_name, "available")
          else
            orig_slot_statuses
          end
      end)

    Experiments.update_experiment(experiment, %{slot_statuses: new_slot_statuses})
  end

  defp all_dependencies_done?(slot_name, %Experiment{
         slot_ordering: _slot_ordering,
         slot_statuses: slot_statuses,
         slot_dependencies: slot_dependencies
       }) do
    dependencies = Map.get(slot_dependencies, slot_name)
    Enum.all?(dependencies, fn dependency -> Map.get(slot_statuses, dependency) == "done" end)
  end

  # def update_slot_status(
  #       %Experiment{
  #         slot_ordering: _slot_ordering,
  #         slot_statuses: orig_slot_statuses,
  #         slot_dependencies: _slot_dependencies
  #       } = experiment,
  #       slot_name,
  #       new_slot_status
  #     ) do
  #   new_slot_statuses = Map.put(orig_slot_statuses, slot_name, new_slot_status)
  #   Experiments.update_experiment(experiment, slot_statuses: new_slot_statuses)
  # end

  def update_slots_from_ulc_specification(
        %Experiment{
          num_variants: num_variants,
          num_chains: num_chains,
          num_generations: num_generations,
          num_players: num_players,
          slot_ordering: slot_ordering,
          slot_statuses: slot_statuses,
          slot_dependencies: slot_dependencies,
          slot_attempt_counts: slot_attempt_counts,
          copy_number: copy_number
        } = experiment
      ) do
    # When we newly create the entries, we're always at the first copy of it all.
    updated_copy_number = copy_number + 1

    {updated_slot_ordering, updated_slot_statuses, updated_slot_dependencies,
     updated_slot_attempt_counts} =
      Enum.reduce(
        1..num_chains,
        {slot_ordering, slot_statuses, slot_dependencies, slot_attempt_counts},
        fn chain, acc ->
          Enum.reduce(1..num_variants, acc, fn variant, acc ->
            Enum.reduce(1..num_generations, acc, fn generation, acc ->
              Enum.reduce(1..num_players, acc, fn player,
                                                  {slot_ordering, slot_statuses,
                                                   slot_dependencies, slot_attempt_counts} ->
                slot_name = "#{updated_copy_number}_#{chain}:#{variant}:#{generation}:#{player}"
                updated_slot_ordering = slot_ordering ++ [slot_name]
                updated_slot_statuses = Map.put(slot_statuses, slot_name, "hold")
                updated_slot_attempt_counts = Map.put(slot_attempt_counts, slot_name, 0)

                dependent_slots =
                  if generation > 1 do
                    Enum.reduce(1..num_players, [], fn cur_player, acc ->
                      dependency_slot_name =
                        "#{updated_copy_number}_#{chain}:#{variant}:#{generation - 1}:#{cur_player}"

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
        end
      )

    Experiments.update_experiment(experiment, %{
      slot_ordering: updated_slot_ordering,
      slot_statuses: updated_slot_statuses,
      slot_dependencies: updated_slot_dependencies,
      slot_attempt_counts: updated_slot_attempt_counts,
      copy_number: updated_copy_number
    })
  end
end