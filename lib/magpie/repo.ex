defmodule Magpie.Repo do
  use Ecto.Repo,
    otp_app: :magpie,
    adapter: Ecto.Adapters.Postgres
end
