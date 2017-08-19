This is a server backend to receive, store and retrieve experiments.

If you encountered any bugs during your experiments please submit an issue.

# Posting experiments
When an experiment is finished, instead of sending it with `mmturkey` to the interface provided by MTurk, please POST the JSON to the following web address: https://procomprag.heroku.com/api/submit_experiment

A sample experiment is provided under the `doc` folder. The code of particular interest would be those in `norming.js`, in the object `slides.thanks`, starting from line 322.

In the `exp.data` object to be submitted, **three extra values are needed**, as shown on lines 334 to 336:
- `author`: The author of this experiment
- `experiment_id`: The codename that the author uses to identify this experiment
- `description`: A brief description of this experiment

Just as in the original experiments with MTurk, the trials are expected to be stored under the `trials` key. Otherwise there could be problems with CSV generation later on.

Note that instead of using the original `turk.submit(exp.data)`, a custom `POST` call was initiated with the code listed below.

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

Note that `crossDomain: true` is needed since the server on Heroku will likely have a different domain than the experiment.

# Retrieving experiment results
Just visit the website at https://procomprag.heroku.com, enter the `experiment_id` and `author` originally contained within the JSON file, and hit "Submit". Authentication mechanisms might be added later, if necessary.

# Additional Notes
- The assumption on the server side when generating the code is that each set of experiment would have the same keys in the JSON file submitted and that each trial of an experiment would have the same keys in an object named `trials`. Violating this assumption might lead to failure in the CSV generation process.

- Please avoid using arrays to store the experiment results as much as possible. For example, if the participant can enter three answers on one trial, it would be better to store the three answers in three k-v pairs, instead of one array.

  However, if an array is used regardless, its items will be separated by a `|` (pipe) in the retrieved CSV file.

- Beware that if there's any field in the results that contains new line characters (for example, the free comments on the experiment from the participant, which might be multiple paragraphs long), the new line characters will be printed literally as `\n` in the final CSV file, since otherwise they would result in actual new lines in the CSV file and thus wreck havoc on the format of the file.


- This app is based on Phoenix Framework and written in Elixir. If you wish to modify the app, please look at the resources available at:
  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
