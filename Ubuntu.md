# Deploying the app on an Ubuntu server

- Allow outside connection to port 80 of your server: `sudo ufw allow 80`
- Install Erlang & Elixir by following the instructions at https://elixir-lang.org/install.html
- Install docker-compose, nodejs, npm, and webpack with `sudo apt-get install docker-compose nodejs npm webpack`
- Clone the repo with `git clone https://github.com/magpie-ea/magpie-backend/`
- cd into the repo and check out the right branch `cd magpie-backend; git checkout ubuntu`
- Start the Postgres database via docker-compose: `docker-compose up -d`
- Build the frontend assets: `cd assets; webpack --mode production; cd ..`
- Build a release: `mix deps.get; MIX_ENV=prod AUTH_USERNAME=your_auth_username AUTH_PASSWORD=your_auth_password mix release`
- Generate a secret key base: `mix phx.gen.secret`
- Run the DB migration: `HOST=ip_of_your_server SECRET_KEY_BASE=secret_key_just_generated _build/prod/rel/magpie/bin/magpie eval "Magpie.ReleaseTasks.db_migrate"`
- Run the app: `HOST=ip_of_your_server SECRET_KEY_BASE=secret_key_just_generated _build/prod/rel/magpie/bin/magpie start`
- The app should be now available on port 80 of your Ubuntu server

Note: SSL/TLS support and auto-starting of the app as a systemd service are not covered above. If these are needed for the app, please refer to https://xiangji.me/2018/08/01/multitenant-phoenix-application-deployment-with-ssl-using-haproxy/
