defmodule Helmsman.ProcessorHelpers do
  import ExUnit.Callbacks

  def setup_config(_context) do
    config_location = "./tmp/config.yml"
    config_content = """
    duration:
      connection:
        address: tcp:host=localhost,port=12345
      message:
        interface: org.neutrino.DBus
        path: /Neutrino/Processing/Processor
        member: duration
        arguments:
         - INPUT
         - OUTPUT
    any:
      connection:
        address: configured_address
      message:
        interface: configured_interface
        path: configured_path
        member: configured_member
        arguments:
         - INPUT
         - OUTPUT
    """

    File.mkdir("./tmp")
    File.write(config_location, config_content)
    Application.put_env(:helmsman, :processors, [config: config_location])
    :ok
  end
end
