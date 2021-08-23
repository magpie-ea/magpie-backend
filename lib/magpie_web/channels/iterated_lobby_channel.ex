defmodule Magpie.IteratedLobbyChannel do
  @moduledoc """
  Channel for maintaining lobbies for iterated experiments where new participants need to wait for previous participants to finish first.
  """
  use MagpieWeb, :channel
  alias Magpie.Experiments
  alias Magpie.Experiments.AssignmentIdentifier

  @doc """
  A client can then decide which experiment results it wants to wait for. Once the experiment results are submitted, they will be informed.

  Note that the assignment identifier should always be the experiment_id followed by the complete 4-tuple.

  Example: "iterated_lobby:45:1:1:1:1"
  """
  def join(
        "iterated_lobby:" <> assignment_identifier,
        _payload,
        socket
      ) do
    case AssignmentIdentifier.from_string(assignment_identifier) do
      {:ok, %AssignmentIdentifier{} = identifier_struct} ->
        send(self(), {:after_participant_join, identifier_struct})
        {:ok, socket}

      {:error, :invalid_format} ->
        {:error, %{reason: "invalid_format"}}
    end
  end

  def handle_info(
        {:after_participant_join, %AssignmentIdentifier{} = assignment_identifier},
        socket
      ) do
    experiment_status = Experiments.get_experiment_status(assignment_identifier)

    case experiment_status.status do
      :completed ->
        experiment_results =
          Experiments.get_one_experiment_results_for_identifier(assignment_identifier)

        # The same as what we do when the waited-on participant submits their results, send the results to all participants waiting for this participant.
        Magpie.Endpoint.broadcast!(
          "iterated_lobby:#{AssignmentIdentifier.to_string(assignment_identifier)}",
          "finished",
          %{results: experiment_results.results}
        )

        {:noreply, socket}

      # I'm not sure if there's a valid case of waiting on an experiment whose status is 0. But I guess I should handle reassignments of dropouts elsewhere.
      _ ->
        {:noreply, socket}
    end
  end
end
