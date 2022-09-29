defmodule Magpie.Experiments.Slots do
  @moduledoc """
  Module for logic related to slots in experiments.
  """
  alias Magpie.Experiments
  alias Magpie.Experiments.Experiment
  alias Magpie.Repo

  @doc """
  Get all slots that are free, in the order that's specificed in the :slot_ordering array.

  It does seem that the most natural place to perform "expand" would be within this function. We'd just need to make sure that we lock the table during the expansion.
  """
  def get_all_available_slots(experiment_id) when is_integer(experiment_id) do
    experiment = Experiments.get_experiment!(experiment_id)
    get_all_available_slots(experiment)
  end

  def get_all_available_slots(
        %Experiment{
          slot_ordering: slot_ordering,
          slot_statuses: slot_statuses
        } = experiment
      ) do
    ordered_free_slots =
      Enum.filter(slot_ordering, fn slot_name ->
        Map.get(slot_statuses, slot_name) == "available"
      end)

    if Enum.empty?(ordered_free_slots) do
      {:ok, expanded_experiment} = expand_experiment(experiment)
      {:ok, expanded_experiment_with_freed_slots} = free_slots(expanded_experiment)
      get_all_available_slots(expanded_experiment_with_freed_slots)
    else
      ordered_free_slots
    end
  end

  def set_slot_to_in_progress(experiment_id, slot_id) do
    Repo.transaction(fn ->
      %Experiment{
        slot_statuses: slot_statuses,
        slot_attempt_counts: slot_attempt_counts
      } = experiment = Experiments.get_experiment!(experiment_id)

      updated_statuses = Map.put(slot_statuses, slot_id, "in_progress")

      updated_attempt_counts =
        Map.update!(slot_attempt_counts, slot_id, fn previous_attempt_count ->
          previous_attempt_count + 1
        end)

      {:ok, experiment} =
        Experiments.update_experiment(experiment, %{
          slot_statuses: updated_statuses,
          slot_attempt_counts: updated_attempt_counts
        })

      experiment
    end)
  end

  defp expand_experiment(%Experiment{is_ulc: true} = experiment) do
    initialize_or_update_slots_from_ulc_specification(experiment)
  end

  @doc """
  Condition for freeing a slot:
  - This slot has condition "hold"
  - All dependencies of this slot has condition "done"

  Guess we'll need to go through all the slots for this check.

  Seems that the ordering might be irrelevant in this case.

  Note that this function only tries to free the slots. It doesn't perform the expansion.
  """
  def free_slots(
        %Experiment{
          slot_ordering: _slot_ordering,
          slot_statuses: orig_slot_statuses,
          slot_dependencies: _slot_dependencies
        } = experiment
      ) do
    # Do everything in one pass. Should be more efficient!
    # We don't have a use for freed_count now. Ignoring it for now.
    {new_slot_statuses, _freed_count} =
      Enum.reduce(orig_slot_statuses, {orig_slot_statuses, 0}, fn
        {slot_name, slot_status}, {orig_slot_statuses, freed_count} ->
          if slot_status == "hold" && all_dependencies_done?(slot_name, experiment) do
            {Map.put(orig_slot_statuses, slot_name, "available"), freed_count + 1}
          else
            {orig_slot_statuses, freed_count}
          end
      end)

    # {Experiments.update_experiment(experiment, %{slot_statuses: new_slot_statuses}), freed_count}
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

  @doc """
  This function is called both when the experiment is first created, and when it runs out of slots and needs to be expanded.

  It will also try to free slots at the end of the action.
  """
  def initialize_or_update_slots_from_ulc_specification(
        %Experiment{
          num_variants: num_variants,
          num_chains: num_chains,
          num_generations: num_generations,
          num_players: num_players,
          slot_ordering: slot_ordering,
          slot_statuses: slot_statuses,
          slot_dependencies: slot_dependencies,
          slot_attempt_counts: slot_attempt_counts,
          trial_players: trial_players,
          copy_number: copy_number
        } = experiment
      ) do
    # When we newly create the entries, we're always at the first copy of it all.
    updated_copy_number = copy_number + 1

    {updated_slot_ordering, updated_slot_statuses, updated_slot_dependencies,
     updated_slot_attempt_counts,
     updated_trial_players} =
      Enum.reduce(
        1..num_chains,
        {slot_ordering, slot_statuses, slot_dependencies, slot_attempt_counts, trial_players},
        fn chain, acc ->
          Enum.reduce(1..num_variants, acc, fn variant, acc ->
            Enum.reduce(1..num_generations, acc, fn generation, acc ->
              Enum.reduce(1..num_players, acc, fn player,
                                                  {slot_ordering, slot_statuses,
                                                   slot_dependencies, slot_attempt_counts,
                                                   trial_players} ->
                slot_name = "#{updated_copy_number}_#{chain}:#{variant}:#{generation}_#{player}"
                updated_slot_ordering = slot_ordering ++ [slot_name]
                updated_slot_statuses = Map.put(slot_statuses, slot_name, "hold")
                updated_slot_attempt_counts = Map.put(slot_attempt_counts, slot_name, 0)

                dependent_slots =
                  if generation > 1 do
                    Enum.reduce(1..num_players, [], fn cur_player, acc ->
                      dependency_slot_name =
                        "#{updated_copy_number}_#{chain}:#{variant}:#{generation - 1}_#{cur_player}"

                      [dependency_slot_name | acc]
                    end)
                  else
                    []
                  end

                updated_slot_dependencies = Map.put(slot_dependencies, slot_name, dependent_slots)

                updated_trial_players = Map.put(trial_players, slot_name, num_players)

                {updated_slot_ordering, updated_slot_statuses, updated_slot_dependencies,
                 updated_slot_attempt_counts, updated_trial_players}
              end)
            end)
          end)
        end
      )

    # {:ok, experiment} =
    Experiments.update_experiment(experiment, %{
      slot_ordering: updated_slot_ordering,
      slot_statuses: updated_slot_statuses,
      slot_dependencies: updated_slot_dependencies,
      slot_attempt_counts: updated_slot_attempt_counts,
      trial_players: updated_trial_players,
      copy_number: updated_copy_number
    })

    # free_slots(experiment)
  end

  def set_slot_as_complete(
        %Experiment{
          slot_statuses: slot_statuses
        } = experiment,
        slot_identifier
      ) do
    new_slot_statuses = Map.put(slot_statuses, slot_identifier, "complete")

    Experiments.update_experiment(experiment, %{slot_statuses: new_slot_statuses})
  end
end
