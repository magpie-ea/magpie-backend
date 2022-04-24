#!/bin/bash

if [[ -z $1 || -z $2 || -z $3 ]]; then
		printf "Please provide an application name, a username, and a password for your Heroku deployment.\n
    Example usage:\n
    sh ./heroku-deploy.sh [application_name] [username] [password]\n
    "
		exit 1
fi

heroku create --buildpack https://github.com/HashNuke/heroku-buildpack-elixir.git
heroku buildpacks:add https://github.com/chrismcg/heroku-buildpack-elixir-mix-release
heroku apps:rename $1
heroku config:set HOST=${1}.herokuapp.com PORT=443
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set POOL_SIZE=18
SEC=$(openssl rand -base64 64 | tr -d '\n')
heroku config:set SECRET_KEY_BASE=$SEC
heroku config:set AUTH_USERNAME=$2
heroku config:set AUTH_PASSWORD=$3
git push heroku master
heroku run "_build/prod/rel/magpie/bin/magpie eval 'Magpie.ReleaseTasks.db_migrate()'"
heroku restart
heroku open
