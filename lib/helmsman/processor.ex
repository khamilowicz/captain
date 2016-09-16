defmodule Helmsman.Processor do

  alias Helmsman.Processor.Config

  defmacro __using__([name: name]) do
    quote do

      @name unquote(name)

      def establish_connection(connection_options) do
        Helmsman.Connection.start_link(connection_options)
      end

      def config_location do
        Application.get_env(:helmsman, :processors)[:config]
      end

      def config do
        Config.open(config_location)[@name]
      end

      def send_message(message) do
        processor_config = config
        %{"connection" => %{"address" => address}} = processor_config
        %{"message" => %{"interface" => interface, "path" => path, "member" => member}} = processor_config
        params = %{interface: interface, path: path, member: member}

        {:ok, connection} = establish_connection(%{address: address})

        Helmsman.Connection.send_message(connection, Map.put(params, :message, message))
      end
    end
  end
end
