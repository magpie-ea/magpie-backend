[
  import_deps: [:ecto, :phoenix],
  inputs: [
    "web/**/*.{ex,exs}",
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "config/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
