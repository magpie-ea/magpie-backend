<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Server Documentation](#server-documentation)
    - [Required values from experiment submissions](#required-values-from-experiment-submissions)
    - [Retrieving experiment results](#retrieving-experiment-results)
- [Experiment Documentation](#experiment-documentation)
    - [Deploying experiments](#deploying-experiments)
    - [Deploying an experiment to Gitlab Pages](#deploying-an-experiment-to-gitlab-pages)
    - [Posting/Publishing experiments](#postingpublishing-experiments)
- [Additional Notes](#additional-notes)

<!-- markdown-toc end -->

This is a server backend to run simple psychological experiments in the browser and online. It
helps receive, store and retrieve data. Work on this project was funded via the project
[Pro^3](http://www.xprag.de/?page_id=4759), which is part of the [XPRAG.de](http://www.xprag.de/) funded by the German Research
Foundation (DFG Schwerpunktprogramm 1727).

If you encounter any bugs during your experiments please [submit an issue](https://github.com/x-ji/ProComPrag/issues).

A live version of the server is currently deployed at https://procomprag.herokuapp.com

# Server Documentation
This section documents the server program.

## Required values from experiment submissions

The server expects to receive results from experiments which are structured in a particular
way, usually stored in variable `exp.data`. For a minimal example, look at the
[Minimal Template](https://github.com/ProComPrag/MinimalTemplate), together with the
documentation of the front end. Data is submitted to the server via HTTP POST.

Data in `exp.data` requires **three crucial values** for the data to be processable by the
server:
- `author`: The author of this experiment
- `experiment_id`: The identifier (can be a string) that the author uses to name this experiment
- `description`: A brief description of this experiment

When an experiment is finished, instead of sending it with `mmturkey` to the interface provided by MTurk/using the original `turk.submit(exp.data)`, please POST the JSON to the following web address: `{SERVER_ADDRESS}/api/submit_experiment`, e.g. https://procomprag.herokuapp.com/api/submit_experiment

The following is an example for the `POST` call.

```javascript
$.ajax({
  type: 'POST',
  url: 'https://procomprag.herokuapp.com/api/submit_experiment',
  // url: 'http://localhost:4000/api/submit_experiment',
  crossDomain: true,
  data: exp.data,
  success: function(responseData, textStatus, jqXHR) {
    console.log(textStatus)
  },
  error: function(responseData,textStatus, errorThrown) {
    alert('Submission failed.');
  }
})
```

The reason for error would most likely be missing mandatory fields (i.e. `author`, `experiment_id`, `description`) in the JSON file.

Note that `crossDomain: true` is needed since the server domain will likely be different the domain where the experiment is presented to the participant.

## Retrieving experiment results
Just visit the server (e.g. at https://procomprag.herokuapp.com), enter the `experiment_id` and `author` originally contained within the JSON file, and hit "Submit". Authentication mechanisms might be added later, if necessary.

## Deploying the Server
This section documents some methods one can use to deploy the server, for both online and offline usages.

### Deployment with Heroku
[Heroku](https://www.heroku.com/) makes it easy to deploy an web app without having to manually manage the infrastructure. It has a free starter tier, which should be sufficient for the purpose of running experiments.

There is an [official guide](https://hexdocs.pm/phoenix/heroku.html) from Phoenix framework on deploying on Heroku. The deployment procedure is based on this guide, but differs in some places.

0. Ensure that you have [the Phoenix Framework installed](https://hexdocs.pm/phoenix/installation.html) and working. However, if you just want to deploy this server and do no development work/change on it at all, you may skip this step.

1. Ensure that you have a [Heroku account](https://signup.heroku.com/) already, and have the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed and working on your computer.

2. Ensure you have [Git](https://git-scm.com/downloads) installed. Clone this git repo with `git clone https://github.com/ProComPrag/ProComPrag.git` or `git clone git@github.com:ProComPrag/ProComPrag.git`.

3. `cd` into the project directory just cloned from your Terminal (or cmd.exe on Windows).

4. Run `heroku create --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"`

5. Run `heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git`

  (N.B.: Although the command line output tells you to run `git push heroku master`, don't do it yet.)

6. You may want to change the application name instead of using the default name. In that case, go to the Heroku Dashboard, find the newly created app, and edit the name in `Settings` panel.

7. Edit line 17 of the file `config/prod.exs`. Replace the part `procomprag.herokuapp.com` after `host` with the app name (shown when you first ran `heroku create`, e.g. `mysterious-meadow-6277.herokuapp.com`, or the app name that you set at step 6, e.g.  `appname.herokuapp.com`). You shouldn't need to modify anything else.

8. Ensure that you're at the top-level project directory. Run
```
heroku addons:create heroku-postgresql:hobby-dev
heroku config:set POOL_SIZE=18
```

9. Run `mix phx.gen.secret`. Then run `heroku config:set SECRET_KEY_BASE="OUTPUT"`, where `OUTPUT` should be the output of the `mix phx.gen.secret` step.

  Note: If you don't have Phoenix framework installed on your computer, you may choose to use some other random generator for this task, which essentially asks for a random 64-character secret. On Mac and Linux, you may run `openssl rand -base64 64`. Or you may use an online password generator [such as the one offered by LastPass](https://lastpass.com/generatepassword.php).

10. Run `git add config/prod.exs`, then `git commit -m "Set app URL"`.

11. Run `git push heroku master`. This will push the repo to the git remote at Heroku (instead of the original remote at Github), and deploy the app.

12. Run `heroku run "POOL_SIZE=2 mix ecto.migrate"`

13. Now, `heroku open` should open the frontpage of the app.

### Local (Offline) Deployment
Normally, running the server in a local development environment would involve installing and configuring Elixir and PostgreSQL. To simplify the development flow, [Docker](https://www.docker.com/) is used instead.

#### First-time installation

The following steps require an internet connection. After they are finished, the server can be launched offline.

1. Install Docker from https://docs.docker.com/install/. You may have to open the application
   in order to let it install its command line tools. Ensure that it's running by typing
   `docker version` in a terminal (e.g., the Terminal app on MacOS or cmd.exe on Windows).

  Note: Linux users would need to install `docker-compose` separately. See relevant instructions at https://docs.docker.com/compose/install/.

2. Ensure you have [Git](https://git-scm.com/downloads) installed. Clone this git repo with `git clone https://github.com/ProComPrag/ProComPrag.git` or `git clone git@github.com:ProComPrag/ProComPrag.git`.

3. Open a terminal (e.g., the Terminal app on MacOS or cmd.exe on Windows), `cd` into the project directory just cloned via git.

4. For the first-time setup, run in the terminal
  ```
  docker volume create --name procomprag-volume -d local
  docker-compose run --rm web mix deps.get
  docker-compose run --rm web npm install
  docker-compose run --rm web node node_modules/brunch/bin/brunch build
  docker-compose run --rm web mix ecto.migrate
  ```

  Note: Linux users might need to manually change the permission of folders with `sudo chown -R $USER:$USER .`. See https://docs.docker.com/compose/rails/#more-compose-documentation.

#### Actual deployment

After installation, you can launch a local server instance which sets up the experiment in your browser and stores the results.

1. Run `docker-compose up` to launch the application every time you want to run the server. Wait until the line `web_1  | [info] Running ProComPrag.Endpoint with Cowboy using http://0.0.0.0:4000` appears in the terminal.

2. Visit localhost:4000 in your browser. You should see the server up and running.

  Note: Windows 7 users who installed *Docker Machine* might need to find out the IP address used by `docker-machine` instead of `localhost`. See https://docs.docker.com/get-started/part2/#build-the-app for details.

Note that the database for storing experiment results is stored at `/var/lib/docker/volumes/procomprag-volume/_data` folder by default. As long as this folder is preserved, experiment results should persist as well.


# Experiment Documentation
This section documents the experiments themselves, which should work independent of the backend (e.g. this program or the default backend provided by Amazon MTurk) used to receive their results.

## Deploying experiments
This program is intended to serve as the backend. An experiment is normally written as a set of static webpages to be hosted on a hosting provider (e.g. [Gitlab Pages](https://about.gitlab.com/features/pages/)) and loaded in the participant's browser. Currently, most experiments collected by this backend are conducted on the crowdsourcing platform [Prolific](https://www.prolific.ac/). However, there should be no restrictions on the way the experiment is run (via e.g. another crowdsourcing platform such as Amazon MTurk, or without any third-party platform at all).

Sample experiments based on the framework originally developed by [Stanford CoCoLab](https://cocolab.stanford.edu/) are provided under `doc/sample-experiments`. The experiment `1c` is for Amazon MTurk and the experiment `italian_free_production` is for Prolific.ac. The entry point for the experiments is the file `index.html`.

## Deploying an experiment to Gitlab Pages
Currently all the experiments are deployed with Gitlab Pages, though other solutions might also be used, e.g. [Bitballon](https://www.bitballoon.com/).

The following is a short description of the deployment process on Gitlab Pages:

1. Go to the folder containing the experiment: e.g. `cd doc/sample-experiments/1c` if you use the deployment script, or `cd test` if you followed the manual method.
2. In your browser, create a gitlab repository, e.g. `test`
3. Initialize git repo: `git init`
4. Add the repository as a remote: `git remote add origin git@gitlab.com:exprag-lab/test.git`
5. Add all the files in the folder: `git add .`
6. Commit: `git commit -m "Initial commit"`
7. Push: `git push -u origin master`
8. Check whether the deployment task was successfully run on Gitlab:
    ![Pipeline](doc/Pipeline.png)
9. The experiment should be available at user-name.gitlab.io/repo-name, e.g. https://exprag-lab.gitlab.io/test/

As an alternative, you may also deploy to a hosting site such as Bitballon by simply dragging and dropping the `public` folder. However, this has the disadvantage of not being able to use a custom domain prefix such as `exprag-lab` when displaying the experiment.

An example of deployed experiment may be found at https://exprag-lab.gitlab.io/experiment-1c/ (Pushed to the repository "experiment-1c" under the user "exprag-lab").

To write a new experiment, you may modify the files `norming.js` and `index.html`. You may also include additional resources in the `experiment` folder, e.g. images to be used in the experiment. The file `css/local-style.css` can be used to define experiment-specific layouts. Due to differences in folder structures, the easiest way to update an experiment is to modify just the source files, and use the `deploy.sh` script to deploy the generated folder into actual Gitlab repos.

## Posting/Publishing experiments
After having successfully deployed an experiment to Gitlab Pages and tested it, you may want to post it on crowdsourcing platforms. To post an experiment on MTurk, you may use the script [Submiterator](https://github.com/feste/Submiterator) together with [MTurk command line tools](https://requester.mturk.com/developer/tools/clt), or you may do so manually.

To post an experiment on Prolific.ac, just follow the instructions given on their user interface and link to the experiment deployed on Gitlab Pages. Please remember to change the variable `exp.completionURL` in the file `norming.js` to match the Prolific completion URL for that particular experiment.

# Additional Notes
- The assumption on the server side when receiving the experiments is that each set of experiment results would have the same keys in the JSON file submitted and that each trial n an experiment would have the same keys in an object named `trials`. Violating this assumption might lead to failure in the CSV generation process. Look at `norming.js` files in the sample experiments for details.

  If new experiments are created by modifying the existing experiment examples, they should work fine.

- Please avoid using arrays to store the experiment results as much as possible. For example, if the participant is allowed to enter three answers on one trial, it would be better to store the three answers under three separate keys, instead of an array under one key.

  However, if an array is used regardless, its items will be separated by a `|` (pipe) in the retrieved CSV file.

- There is limited guarantee on DB security on Heroku's Hobby grade. The experiment authors are expected to take responsibility of the results. They should retrieve them and perform backups as soon as possible.

- This app is based on Phoenix Framework and written in Elixir. If you wish to modify the app, please look at the resources available at:
  - Official website: http://www.phoenixframework.org/
  - Guides: http://phoenixframework.org/docs/overview
  - Docs: https://hexdocs.pm/phoenix
  - Mailing list: http://groups.google.com/group/phoenix-talk
  - Source: https://github.com/phoenixframework/phoenix
