use Mix.Config

config :helmsman, :handler,
   mod: Helmsman.TestConnection,
   connection: Helmsman.TestConnection

