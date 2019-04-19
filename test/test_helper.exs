ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(BABE.Repo, :manual)

# Wallaby
# Need to bypass the basic auth
url = BABE.Endpoint.url()

url =
  String.replace(
    url,
    "//",
    "//" <>
      Application.get_env(:babe, :authentication)[:username] <>
      ":" <> Application.get_env(:babe, :authentication)[:password] <> "@"
  )

Application.put_env(:wallaby, :base_url, url)
{:ok, _} = Application.ensure_all_started(:wallaby)
