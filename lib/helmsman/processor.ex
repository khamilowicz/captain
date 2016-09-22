defmodule Helmsman.Processor do

  alias Helmsman.Processor.Config

  defmodule Connection do
    @connection_provider Application.get_env(:helmsman, :connection_provider)

    def connection_provider, do: @connection_provider

    def send_message(connection, message), do:
    connection_provider.send_message(connection, message)

    def establish_connection(connection_options), do:
    connection_provider.connect(connection_options)

    def disconnect(connection_options_or_pid), do:
    connection_provider.disconnect(connection_options_or_pid)

    def connection_options(%{"connection" => %{"address" => address}}), do:
    %{address: address}
  end

  defmodule Message do
    defstruct [:name, :options, :input, :allowed ]

    def build(allowed_input), do: %__MODULE__{allowed: allowed_input}

    def put_options(message, %{"interface" => interface, "path" => path, "member" => member, "destination" => destination}), do:
      put_options(message, %{interface: interface, path: path, member: member, destination: destination})
    def put_options(message, options), do: %{message | options: options}

    def put_input(message, input), do: put_in message.input, Map.take(input, message.allowed)

    def put_name(message, name), do: %{message | name: name}

    def format(%{name: name, input: input, options: options}) do
      identifier = generate_identifier
      Map.merge(options, %{message: {name, identifier, input}, identifier: identifier})
    end

    def generate_identifier, do:
      Base.url_encode64(:crypto.strong_rand_bytes(10))
  end

  defmacro __using__(opts) do
    name = Keyword.get(opts, :name, "standard")
    quote(location: :keep) do

      @name unquote(name)

      def config_location, do:
      Application.get_env(:helmsman, :processors)[:config]

      def config(), do: config(@name)
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
  end
end
