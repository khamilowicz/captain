use Mix.Config

config :helmsman, :processors, [
   duration: [
     connection: %{
       hostname: "localhost",
       port: "12345"
     }
   ]
  ]
