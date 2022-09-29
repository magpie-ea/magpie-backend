defmodule Magpie.Experiments.TrialIdentifier do
  @derive Jason.Encoder
  defstruct [:experiment_id, :copy_number, :trial_spec, :player_number]

  alias Magpie.Experiments.ExperimentStatus
end
