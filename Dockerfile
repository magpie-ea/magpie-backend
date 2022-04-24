FROM bitwalker/alpine-elixir-phoenix:1.13.1

WORKDIR /app

COPY mix.exs .
COPY mix.lock .

CMD mix deps.get && mix deps.compile && mix assets.deploy && mix ecto.setup && mix phx.server
