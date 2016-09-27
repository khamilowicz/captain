defmodule Helmsman.Handler.DBus do

  alias Helmsman.Handler.DBus.{Config, Connection, Message, FileManager, Cleanup}

  #TODO Make it more flexible
  @file_host_port 9000

  def config_location,
  do: Application.get_env(:helmsman, :processors)[:config]

  def config(name) do
    config = Config.open(config_location)
    config[name] || config["any"]
  end

  def connection_config(name), do: Map.get(config(name), "connection")

  def path_to_url(processor, path) do
    address = connection_config(processor) |> Map.get("address")
    case extract(address, :host) do
      nil -> path
      [host, _port] -> "http://#{host}:#{@file_host_port}/#{path}"
    end
  end

  def extract(nil, :host), do: nil
  def extract(tcp_address, :host) do
    case Regex.run(~r{tcp:host=(.+),port=(.+)}, tcp_address, capture: :all_but_first) do
      [host, port] -> [host, port]
      _ -> nil
    end
  end

  def delete_files(connection, filenames), do: Enum.map(filenames, &delete_file(connection, &1))
  def delete_file(conn_options, filename) do
    params =
      Message.build([])
      |> Message.put_options(config("delete-file")["message"])
      |> Message.put_input({filename})
      |> Message.format

    with {:ok, connection} <- Connection.establish_connection(conn_options) do
      Connection.send_async_message(connection, params)
    end
  end

  def fetch(conn_options, file_url) do
    [processor_host, _port] = conn_options |> Map.get(:address) |> extract(:host) |> IO.inspect
    uri = URI.parse(file_url) |> IO.inspect
    if uri.host == processor_host do
      uri.path |> String.trim_leading("/")
    else
      do_fetch(conn_options, file_url)
    end
  end

  def do_fetch(conn_options, file_url) do
    file_path = FileManager.generate_file_name("fetch")

    params =
      Message.build([])
      |> Message.put_options(config("fetch-file")["message"])
      |> Message.put_identifier(file_url)
      |> Message.put_input({file_url, file_path})
      |> Message.format

    with {:ok, connection} <- Connection.establish_connection(conn_options),
         {:ok, file_path} <- Connection.send_message(connection, params),
         :ok <- Connection.disconnect(connection)
    do
      file_path
    else
      any -> throw(:fetch_error)
    end
  end

  def fetch_files(input, conn_options) do
    Helmsman.Utils.map_only(input, &is_url?/1, &fetch(conn_options, &1))
  end
  def is_url?("http" <> _ = url), do: true
  def is_url?(_), do: false

  def start_processor(name, input, extra) do

    processor_config = config(name)
    conn_options = Connection.connection_options(processor_config)
    input = fetch_files(input, conn_options)

    message =
      Message.build(processor_config["message"]["arguments"])
      |> Message.put_name(name)
      |> Message.put_input(input)
      |> Message.put_options(processor_config["message"])

    message_params = Message.format(message)

    with {:ok, connection} <- Connection.establish_connection(conn_options),
         {:ok, result} <- Connection.send_message(connection, message_params),
         :ok <- cleanup(conn_options, input, extra[:cleaner])
    do
      {:ok, paths_to_urls(name, extra[:output], input)}
    else
      # TODO: make it better
      any -> {:error, any}
    end
  end

  def paths_to_urls(processor, output, input) do
    input
    |> Map.take(Map.keys(output))
    |> Enum.map(fn {k, v} -> {k, path_to_url(processor, v)} end)
    |> Enum.into(%{})
  end

  def cleanup(connection, input, cleaner) do
    temp_files = Map.values(input) |> Enum.filter(&FileManager.filename?/1)
    Cleanup.add_cleanup(cleaner, __MODULE__, :delete_files, [connection, temp_files])
  end
end
