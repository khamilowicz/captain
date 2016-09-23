defmodule Helmsman.Processor.Connection do
  @connection_provider Application.get_env(:helmsman, :connection_provider)

  def connection_provider, do: @connection_provider

  def send_message(connection, message),
  do: connection_provider.send_message(connection, message)

  def send_async_message(connection, message),
  do: connection_provider.send_async_message(connection, message)

  def establish_connection(connection_options),
  do: connection_provider.connect(connection_options)

  def disconnect(connection_options_or_pid),
  do: connection_provider.disconnect(connection_options_or_pid)

  def connection_options(%{"connection" => %{"address" => address}}),
  do: %{address: address}
end
