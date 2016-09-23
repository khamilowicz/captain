defmodule Helmsman.Processor do

  alias Helmsman.Processor.{Config, Connection, Message, FileManager, Cleanup}

  def config_location,
  do: Application.get_env(:helmsman, :processors)[:config]

  def config(name) do
    config = Config.open(config_location)
    config[name] || config["any"]
  end

  def delete_files(connection, filenames), do: Enum.map(filenames, &delete_file(connection, &1))
  def delete_file(conn_options_or_connection, filename) do
    params =
      Message.build([])
      |> Message.put_options(config("delete-file")["message"])
      |> Message.put_input({filename})
      |> Message.format

    with {:ok, connection} <- Connection.establish_connection(conn_options_or_connection) do
      Connection.send_async_message(connection, params)
    end
  end

  def start_processor(name, input, extra) do
    processor_config = config(name)

    message =
      Message.build(processor_config["message"]["arguments"])
      |> Message.put_name(name)
      |> Message.put_input(input)
      |> Message.put_options(processor_config["message"])

    message_params = Message.format(message)
    conn_options = Connection.connection_options(processor_config)

    with {:ok, connection} <- Connection.establish_connection(conn_options),
         {:ok, result} <- Connection.send_message(connection, message_params),
         :ok <- cleanup(conn_options, input, extra[:cleaner])
    do
      {:ok, result}
    else
      # TODO: make it better
      any -> {:error, any}
    end
  end

  def cleanup(connection, input, cleaner) do
    temp_files = Map.values(input) |> Enum.filter(&FileManager.filename?/1)
    Cleanup.add_cleanup(cleaner, __MODULE__, :delete_files, [connection, temp_files])
  end
end
