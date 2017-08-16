defmodule WoqWebapp.ExperimentController do
  @moduledoc false
  use WoqWebapp.Web, :controller

  alias WoqWebapp.Experiment

  def create(conn, experiment_params) do
    changeset = Experiment.changeset(%Experiment{}, experiment_params)
    case Repo.insert(changeset) do
      {:ok, _} ->
        # created is 201
        # Currently I don't think there's a need to send the created resource back. Just acknowledge that the information is received.
        send_resp(conn, :created, "")
      {:error, _} ->
        # unprocessable entity is 422
        send_resp(conn, :unprocessable_entity, "")
    end
  end
end
