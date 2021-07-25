# Deploying magpie-backend

magpie-backend is now deployed using Elixir's native release mechanism and requires at least Elixir v1.11 to run. When running the app, the following environment variables need to be provided:

Mandatory:
- `HOST`: The URL of the host the app is supposed to run on, e.g. "www.example.com"
- `SECRET_KEY_BASE`: A random secret for the Phoenix app. A random one be generated with `phx.gen.secret`
- `DATABASE_URL`: The URL to the production database. If you use Heroku, this environment variable will be automatically generated
- `AUTH_USERNAME`: The auth username to access the system
- `AUTH_PASSWORD`: The auth password to access the system

Optional:
- `PORT`: The port at which the app is available. By default 443
- `MAGPIE_PATH`: The path of the app at the host. By default `/`. Useful for when deploying the app in a multi-tenant way.
- `URL_SCHEME`: Whether the app is run on `https` or `http`. By default `https`
- `MAGPIE_NO_BASIC_AUTH`: Whether to allow accessing the app without basic name (i.e. username + pw)
    Note: Even with this variable set to `true`, the `AUTH_USERNAME` and `AUTH_PASSWORD` environment variables are still needed to start the app.
- `REAL_URL`: Useful when the app is behind a reverse proxy and you need to actually use the URL shown to the outside by the reverse proxy, e.g. in template generation in web/templates/experiments/edit.html.eex
