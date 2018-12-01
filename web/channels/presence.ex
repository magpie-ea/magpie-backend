defmodule BABE.Presence do
  use Phoenix.Presence, otp_app: :babe, pubsub_server: BABE.PubSub
end
