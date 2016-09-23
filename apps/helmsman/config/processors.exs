use Mix.Config

config :helmsman, :processors, [
  # config: "/vagrant/apps/helmsman/dbus/config.yml"
  config: "/Users/kham/Work/radiokit/audio_addon/captain/apps/helmsman/dbus/config.yml"
  ]

config :mapmaker, :processors, %{
  "any" => Helmsman.Processor.General
  }
config :mapmaker, :postprocessors, %{
  "download" => Helmsman.Postprocessors.Download
  }
config :mapmaker, :specs, %{
  max_retries: 5,
  }
