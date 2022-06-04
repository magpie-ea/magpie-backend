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
end
