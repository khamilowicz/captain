defmodule Helmsman.Processor do

  alias Helmsman.Processor.Config

  defmacro __using__(opts) do
    name = Keyword.get(opts, :name, "standard")
    quote do

      @name unquote(name)
      @connection_provider Application.get_env(:helmsman, :connection_provider)

      def connection_provider, do: @connection_provider

      def establish_connection(connection_options) do
        connection_provider.start_link(connection_options)
      end

      def config_location do
        Application.get_env(:helmsman, :processors)[:config]
      end

      def config(), do: config(@name)
      def config(name), do: Config.open(config_location)[name]

      def send_message(message), do: send_message(message, @name)
      def send_message(message, name) do
        processor_config = config(name)
        %{"connection" => %{"address" => address}} = processor_config
        %{"message" => %{"interface" => interface, "path" => path, "member" => member}} = processor_config
        params = %{interface: interface, path: path, member: member}

        {:ok, connection} = establish_connection(%{address: address})

        connection_provider.send_message(connection, Map.put(params, :message, message))
      end
    end
  end
end
