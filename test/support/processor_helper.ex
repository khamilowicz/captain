defmodule Helmsman.ProcessorHelpers do
  import ExUnit.Callbacks

  def setup_config(context) do
    config_location = "./tmp/config.yml"
    config_content = """
    duration:
      connection:
        address: tcp:host=localhost,port=12345
      message:
        interface: org.neutrino.DBus
        path: /Neutrino/Processing/Processor
        member: duration
    """

    File.mkdir("./tmp")
    File.write(config_location, config_content)
    Application.put_env(:helmsman, :processors, [config: config_location])
    :ok
  end
end
