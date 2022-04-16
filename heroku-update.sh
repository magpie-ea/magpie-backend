#!/bin/bash


git pull origin master

if [[ -z $1 ]]; then
		echo "NOTE: Version tag not specified. Updating to the latest commit on the master branch by default."
else
    git checkout $1
fi

git push heroku master
heroku run "_build/prod/rel/magpie/bin/magpie eval 'Magpie.ReleaseTasks.db_migrate()'"
heroku open
