defmodule Helmsman.Processor do

  alias Helmsman.Processor.Config
  alias Helmsman.Connection.MessageParser

  defmacro __using__(opts) do
    name = Keyword.get(opts, :name, "standard")
    quote(location: :keep) do

      @name unquote(name)
      @connection_provider Application.get_env(:helmsman, :connection_provider)

      def connection_provider, do: @connection_provider

      def establish_connection(connection_options), do:
        connection_provider.start_link(connection_options)

      def config_location, do:
        Application.get_env(:helmsman, :processors)[:config]

      def config(), do: config(@name)
      def config(name) do
        config = Config.open(config_location)
        config[name] || config["any"]
      end

      def connection_options(%{"connection" => %{"address" => address}}), do:
        %{address: address}

      def message_options(%{"message" => %{"interface" => interface, "path" => path, "member" => member}}), do:
        %{interface: interface, path: path, member: member}

      def allowed_input(input, %{"message" => %{"arguments" => args}}), do:
        Map.take(input, args)

      def generate_identifier, do:
        Base.url_encode64(:crypto.rand_bytes(10))

      def start_processor(name, input) do
        processor_config = config(name)

        connection_options = connection_options(processor_config)
        message_params = message_options(processor_config)
        parsed_input = allowed_input(input, processor_config)

        message = {name, generate_identifier, parsed_input}

        with {:ok, connection} <- establish_connection(connection_options(processor_config)) do
          connection_provider.send_message(connection, message_params)
        end
      end
    end
  end
end
