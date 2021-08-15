defmodule Magpie.Experiments.AssignmentIdentifier do
  defstruct [:experiment_id, :variant, :chain, :generation, :player]

  alias Magpie.Experiments.ExperimentStatus

  def from_string(identifier_string) when is_binary(identifier_string) do
    case String.split(identifier_string, ":") do
      [experiment_id, variant, chain, generation, player] ->
        %__MODULE__{
          experiment_id: experiment_id,
          variant: variant,
          chain: chain,
          generation: generation,
          player: player
        }

      _ ->
        {:error, :invalid_format}
    end
  end

  def from_experiment_status(%ExperimentStatus{} = experiment_status) do
    %__MODULE__{
      experiment_id: experiment_status.experiment_id,
      variant: experiment_status.variant,
      chain: experiment_status.chain,
      generation: experiment_status.generation,
      player: experiment_status.player
    }
  end

  def to_string(%__MODULE__{} = assignment_identifier) do
    "#{assignment_identifier.experiment_id}:#{assignment_identifier.chain}:#{assignment_identifier.variant}:#{assignment_identifier.generation}:#{assignment_identifier.player}"
  end

  def to_string(%ExperimentStatus{} = experiment_status) do
    "#{experiment_status.experiment_id}:#{experiment_status.chain}:#{experiment_status.variant}:#{experiment_status.generation}:#{experiment_status.player}"
  end

  def to_string(_) do
    {:error, :invalid_format}
  end
end
