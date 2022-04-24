# Note that this Docker configuration is exclusively for starting up the server on a local machine so that experiments can be run by researchers even without any internet connection. The production web app is NOT deployed via Docker for now.
FROM elixir:1.12

MAINTAINER Xiang Ji <hi@xiangji.me>

RUN mix local.hex --force \
  && mix archive.install hex phx_new 1.6.7 \
 && apt-get update \
 && curl -sL https://deb.nodesource.com/setup_14.x | bash \
 && apt-get install -y apt-utils \
 && apt-get install -y nodejs \
 && apt-get install -y build-essential \
 && apt-get install -y inotify-tools \
 && mix local.rebar --force

RUN mkdir /app
# Copy all the files in the current git repo into the target /app folder
COPY . /app
# Similar to cd
WORKDIR /app

EXPOSE 4000

# This thing apparently isn't working. No idea why.
RUN mix deps.get \
&& mix deps.compile \
&& cd assets; npm install; cd ..

CMD ["sh", "./docker-entrypoint.sh"]
