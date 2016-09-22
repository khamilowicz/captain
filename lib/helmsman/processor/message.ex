defmodule Helmsman.Processor.Message do
  defstruct [:name, :options, :input, :allowed ]

  def build(allowed_input), do: %__MODULE__{allowed: allowed_input}

  def put_options(message, %{"interface" => interface, "path" => path, "member" => member, "destination" => destination}),
  do: put_options(message, %{interface: interface, path: path, member: member, destination: destination})
  def put_options(message, options), do: %{message | options: options}

  def put_input(message, input), do: put_in message.input, Map.take(input, message.allowed)

  def put_name(message, name), do: %{message | name: name}

  def format(%{name: name, input: input, options: options}) do
    identifier = generate_identifier
    Map.merge(options, %{message: {name, identifier, input}, identifier: identifier})
  end

  def generate_identifier,
  do: Base.url_encode64(:crypto.strong_rand_bytes(10))
end
