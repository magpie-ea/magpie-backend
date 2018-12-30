defmodule BABE.ClearDB do
  alias BABE.{Repo, ExperimentStatus}
  require Ecto.Query

  @doc """
  Set all ExperimentStatus that are "in progress" (1) to "available" (0) if the app is restarted.

  Actually, channels should reconnect automatically on server restart. However, such reconnections might not be handled totally satisfactorily anyways. Might be better to just let the users restart the experiment altogether, if this ever happens.
  """
  def clear_in_progress_experiments_on_restart do
    Ecto.Query.from(p in ExperimentStatus, where: p.status == 1)
    |> Repo.update_all(set: [status: 0])
  end
end
