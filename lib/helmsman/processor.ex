defmodule Helmsman.Processor do

  alias Helmsman.Processor.Config
  alias Helmsman.Processor.Connection
  alias Helmsman.Processor.Message

  def config_location,
  do: Application.get_env(:helmsman, :processors)[:config]

  def config(name) do
    config = Config.open(config_location)
    config[name] || config["any"]
  end

  def start_processor(name, input) do
    processor_config = config(name)

    message_params =
      Message.build(processor_config["message"]["arguments"])
      |> Message.put_name(name)
      |> Message.put_input(input)
      |> Message.put_options(processor_config["message"])
      |> Message.format

    connection_result =
      processor_config
      |> Connection.connection_options
      |> Connection.establish_connection

    with {:ok, connection} <- connection_result,
         {:ok, result} <- Connection.send_message(connection, message_params)
    do
      {:ok, result}
    else
      # TODO: make it better
      any -> {:error, any}
    end
  end
end
