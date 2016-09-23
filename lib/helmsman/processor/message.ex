defmodule Helmsman.Processor.Message do
  defstruct [:name, :options, :input, :allowed, :identifier]

  def build(allowed_input), do: %__MODULE__{allowed: allowed_input, identifier: generate_identifier}

  def put_options(message, %{"interface" => interface, "path" => path, "member" => member, "destination" => destination}),
  do: put_options(message, %{interface: interface, path: path, member: member, destination: destination})
  def put_options(message, options), do: %{message | options: options}

  def put_input(message, input) when is_tuple(input), do: put_in message.input, input
  def put_input(message, input), do: put_in message.input, {message.name, message.identifier, Map.take(input, message.allowed)}

  def put_name(message, name), do: %{message | name: name}
  def get_identifier(message), do: message.identifier

  def format(%{name: name, input: input, options: options, identifier: identifier}) do
    Map.merge(options, %{message: input, identifier: identifier})
  end

  def generate_identifier,
  do: Base.url_encode64(:crypto.strong_rand_bytes(10))

end
