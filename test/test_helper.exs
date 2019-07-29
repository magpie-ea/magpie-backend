ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Magpie.Repo, :manual)

# Wallaby
# Need to bypass the basic auth
url = Magpie.Endpoint.url()

url =
  String.replace(
    url,
    "//",
    "//" <>
      Application.get_env(:magpie, :authentication)[:username] <>
      ":" <> Application.get_env(:magpie, :authentication)[:password] <> "@"
  )

Application.put_env(:wallaby, :base_url, url)
{:ok, _} = Application.ensure_all_started(:wallaby)
