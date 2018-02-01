#!/bin/bash

## This script aims to automate these steps:
# 1. Copy everything in `experiment` folder into `public` folder
# 2. Copy the `_shared` folder, which was originally at root level, into `public`  folder
# 3. Change the name of `norming.html` to `index.html`
# 4. Change all the references to `../../_shared` to `_shared`
# 5. The page should be rebuilt at each push, or at each manual launch of the CI task on Gitlab

usage=$"$(basename "$0") EXPERIMENT_NAME DEPLOYMENT_PATH

where:
      EXPERIMENT_NAME: The name of the folder containing the experiment you want to deploy, e.g. \"spanish_free_production\"
      DEPLOYMENT_PATH: The path of the folder to contain processed repositories for deployment, e.g. \"../gitlab-deployments\". If empty, defaults to \"..\"
"

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    echo "$usage"
    exit
fi

experiment_name=$1
deployment_path=$2

mkdir $deployment_path/$experiment_name
cp -r $experiment_name/experiment $deployment_path/$experiment_name/public
cp -r _shared $deployment_path/$experiment_name/public/_shared
cp gitlab-ci-template.yml $deployment_path/$experiment_name/.gitlab-ci.yml
cd $deployment_path/$experiment_name/public
mv norming.html index.html
sed -i.bak -e "s/\.\.\/\.\.\/_shared/_shared/g" index.html
echo "*.bak" >| ../.gitignore

echo "All done. You will still need to go to the deployment folder to manually initialize a git repo, commit and push to Gitlab.

To push changes. You may delete all the contents in the deployment folder except for the .git folder and run the script again."
