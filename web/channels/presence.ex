defmodule Magpie.Presence do
  use Phoenix.Presence, otp_app: :magpie, pubsub_server: Magpie.PubSub
end
