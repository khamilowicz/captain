use Mix.Config

config :helmsman, :handler,
   mod: Helmsman.Handler.DBus,
   connection: Helmsman.Handler.DBus.Connection
