This is a server backend to receive, store and retrieve online linguistics (pragmatics) experiments. This program was written for the research program [XPRAG.de](http://www.xprag.de/)

If you encountered any bugs during your experiments please [submit an issue](https://github.com/x-ji/ProComPrag/issues).

A live version of the server is deployed at https://procomprag.herokuapp.com

# Deploying experiments
This program is intended to serve as the backend. An experiment is normally written as a set of static webpages to be hosted on a hosting provider (e.g. [Gitlab Pages](https://about.gitlab.com/features/pages/)) and loaded in the participant's browser (e.g. when they start the experiment via a crowdsourcing website such as Amazon MTurk or Prolific.ac). The experiments should be able to be shown regardless of the backend used.

Sample experiments for MTurk and Prolific.ac are provided under `doc/sample-experiments`. Open `norming.html` files to show the experiments. The `deploy.sh` file prepares an experiment to be deployed to Gitlab Pages. You would still need to create a repository on Gitlab, init a git repo and push.

# Required values from experiment submissions
In the `exp.data` object to be submitted, **three extra values are needed**, as shown on lines 386 to 388 in `/doc/sample_experiments/italian_free_production/experiment/js/norming.js`:
- `author`: The author of this experiment
- `experiment_id`: The identifier (can be a string) that the author uses to name this experiment
- `description`: A brief description of this experiment

Just as in the original experiments with MTurk, the trials are expected to be stored under the `trials` key in the JSON file. Otherwise there could be problems with CSV generation later on.

When an experiment is finished, instead of sending it with `mmturkey` to the interface provided by MTurk/using the original `turk.submit(exp.data)`, please POST the JSON to the following web address: `{SERVER_ADDRESS}/api/submit_experiment`, e.g. https://procomprag.herokuapp.com/api/submit_experiment

The following is a code example for the `POST` call.

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

# Retrieving experiment results
Just visit the server (e.g. at https://procomprag.herokuapp.com), enter the `experiment_id` and `author` originally contained within the JSON file, and hit "Submit". Authentication mechanisms might be added later, if necessary.

# Additional Notes
- The assumption on the server side when receiving the experiments is that each set of experiment would have the same keys in the JSON file submitted and that each trial of an experiment would have the same keys in an object named `trials`. Violating this assumption might lead to failure in the CSV generation process. Look at `norming.js` files in the sample experiments for details.

- Please avoid using arrays to store the experiment results as much as possible. For example, if the participant is allowed to enter three answers on one trial, it would be better to store the three answers in three k-v pairs, instead of one array.

  However, if an array is used regardless, its items will be separated by a `|` (pipe) in the retrieved CSV file.

- There is limited guarantee on DB security on Heroku's Hobby grade. The experiment authors are expected to take responsibility of the results. They should retrieve them and perform backups as soon as possible.

- This app is based on Phoenix Framework and written in Elixir. If you wish to modify the app, please look at the resources available at:
  - Official website: http://www.phoenixframework.org/
  - Guides: http://phoenixframework.org/docs/overview
  - Docs: https://hexdocs.pm/phoenix
  - Mailing list: http://groups.google.com/group/phoenix-talk
  - Source: https://github.com/phoenixframework/phoenix
