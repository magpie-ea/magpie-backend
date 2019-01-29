# Changelog

## [0.2.2] - 2018-01-29

### Fixed

- Last updated time of experiments are now correctly displayed again.
- Minor bug fixes on experiment results and custom record submissions.

## [0.2.1] - 2018-01-09

### Changed

- The local deployment no longer uses basic authentication.

### Fixed

- Allow socket connection from any host, since we don't constrain where the user hosts the frontend \_babe experiment.
- Use `Multi.insert` instead of `Multi.insert_all` in `ExperimentController.create/2`, since the latter seems to fail with SQLite in local deployment. See https://github.com/elixir-sqlite/sqlite_ecto2/issues/231

## [0.2.0] - 2018-01-05

### Added

- <variant-nr, chain-nr, realization-nr> based complex experiment mechanism.

### Removed

- `:maximum_submissions` column from `:experiments` table. There is no need to automatically deactivate an experiment.
- `:current_submissions` column from `:experiments` table. The number of submissions is now directly counted from the DB.
- `:is_interactive_experiment` and `:num_participants_interactive_experiment` columns from `:experiments` table. The previous interactive experiment mechanism is now replaced by the tritupled-based complex experiment mechanism.

### Fixed

- A bug where if the `{author_name, experiment_name}` of two experiments are completely the same, the results cannot be downloaded properly.
