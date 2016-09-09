defprotocol Mapmaker.Pipeable do
  @dialyzer {:nowarn_function, __protocol__: 1}

  def required(pipeable, switch \\ true)

  def has_input_key?(pipeable, key)
  def has_input_keys?(pipeable, key)

  def put_output(pipeable, key, output)
  def get_output(pipeable, key)

  def put_input(pipeable, key, output)
  def get_input(pipeable, key)

  def input_keys(pipeable)
  def output_keys(pipeable)

end

defimpl Mapmaker.Pipeable, for: Any do

  alias Mapmaker.Utils

  @type io_key :: String.t

  @spec required(Mapmaker.Pipeable.t, boolean) :: Mapmaker.Pipeable.t
  def required(spec, switch \\ true) do
    %{spec | required: switch}
  end

  @spec put_input(Mapmaker.Pipeable.t, atom, io_key) :: Mapmaker.Pipeable.t
  def put_input(spec, key, input) do
    put_in spec.input[key], input
  end

  @spec put_output(Mapmaker.Pipeable.t, atom, io_key) :: Mapmaker.Pipeable.t
  def put_output(spec, key, output) do
    put_in spec.output[key], output
  end

  @spec get_input(Mapmaker.Pipeable.t, atom) :: io_key
  def get_input(spec, input), do: spec.input[input]

  @spec input_keys(Mapmaker.Pipeable.t) :: [io_key]
  def input_keys(spec) do
    spec.input
    |> Map.values
    |> Enum.map(fn
      %{key: input_key} -> input_key
      input_key -> input_key
    end)
  end

  @spec has_input_keys?(Mapmaker.Pipeable.t, [String.t]) :: boolean
  def has_input_keys?(spec, keys) do
    Utils.is_sublist?(keys, input_keys(spec))
  end

  @spec has_input_key?(Mapmaker.Pipeable.t, String.t) :: boolean
  def has_input_key?(spec, key) do
    key in input_keys(spec)
  end

  @spec get_output(Mapmaker.Pipeable.t, atom) :: io_key
  def get_output(spec, output), do: spec.output[output]

  @spec output_keys(Mapmaker.Pipeable.t) :: [io_key]
  def output_keys(spec), do: Map.values(spec.output)

end
