defmodule Magpie.Experiments.AssignmentIdentifier do
  @derive Jason.Encoder
  defstruct [:experiment_id, :copy_number, :attempt_count, :trial, :player_number]

  def from_string(identifier_string) when is_binary(identifier_string) do
    case String.split(identifier_string, "_") do
      [experiment_id, copy_number, attempt_count, trial, player_number] ->
        {:ok,
         %__MODULE__{
           experiment_id: experiment_id,
           copy_number: copy_number,
           attempt_count: attempt_count,
           trial: trial,
           player_number: player_number
         }}

      _ ->
        {:error, :invalid_format}
    end
  end

  # def from_experiment_status(%ExperimentStatus{} = experiment_status) do
  #   %__MODULE__{
  #     experiment_id: experiment_status.experiment_id,
  #     variant: experiment_status.variant,
  #     chain: experiment_status.chain,
  #     generation: experiment_status.generation,
  #     player: experiment_status.player
  #   }
  # end

  def to_string(assignment_identifier, include_player \\ true)

  def to_string(%__MODULE__{} = assignment_identifier, include_player) do
    base =
      "#{assignment_identifier.experiment_id}_#{assignment_identifier.copy_number}_#{assignment_identifier.attempt_count}_#{assignment_identifier.trial}"

    if include_player do
      base <> "_#{assignment_identifier.player_number}"
    else
      base
    end
  end

  # def to_string(%ExperimentStatus{} = experiment_status, include_player) do
  #   base =
  #     "#{experiment_status.experiment_id}:#{experiment_status.chain}:#{experiment_status.variant}:#{experiment_status.generation}"

  #   if include_player do
  #     base <> ":#{experiment_status.player}"
  #   else
  #     base
  #   end
  # end

  def to_string(_, _include_player) do
    {:error, :invalid_format}
  end
end
