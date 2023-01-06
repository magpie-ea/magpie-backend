# This Dockerfile creates a release image
# while the Dockerfile in the root dir of this
# repo creates a development image
FROM elixir:1.13

RUN mix local.hex --force \
 && mix archive.install hex phx_new \
 && apt-get update \
 && curl -sL https://deb.nodesource.com/setup_14.x | bash \
 && apt-get install -y apt-utils \
 && apt-get install -y nodejs \
 && apt-get install -y build-essential \
 && apt-get install -y inotify-tools \
 && mix local.rebar --force

# Similar to cd
WORKDIR /app

COPY app/assets assets

RUN cd assets \
    && npm install

RUN mix assets.deploy

COPY app/priv priv

ENV MIX_ENV="prod"

COPY app/mix.exs app/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY app/config/config.exs app/config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY app/lib lib

COPY app/config/releases.exs config/

COPY app/rel rel

ADD entrypoint.sh /

EXPOSE 4000

CMD ["/bin/bash", "/entrypoint.sh"]
