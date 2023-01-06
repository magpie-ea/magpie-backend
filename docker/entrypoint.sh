#! /bin/env bash
mix phx.digest
mix release --force --overwrite
./_build/prod/rel/magpie/bin/magpie eval 'Magpie.ReleaseTasks.db_migrate()' || true
./_build/prod/rel/magpie/bin/magpie eval 'Magpie.ReleaseTasks.db_migrate()'
./_build/prod/rel/magpie/bin/magpie start
