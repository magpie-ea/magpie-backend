defmodule BABE.Repo do
  use Ecto.Repo,
    otp_app: :babe,
    adapter: Ecto.Adapters.Postgres
end
