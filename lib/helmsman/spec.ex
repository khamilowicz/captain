defmodule Helmsman.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct
  Also updates

    Examples

      iex> spec = %Helmsman.Spec{}
      iex> spec = Helmsman.Spec.put_processor(spec, MyProcessor)
      iex> Helmsman.Spec.get_processor(spec)
      MyProcessor
      iex> spec = Helmsman.Spec.put_input(spec, :in1, "a")
      iex> spec = Helmsman.Spec.put_output(spec, :out1, "b")
      iex> Helmsman.Spec.get_input(spec, :in1)
      "a"
      iex> Helmsman.Spec.get_output(spec, :out1)
      "b"
  """

  alias Helmsman.Processors

  @type t :: %{
    processor: module,
    input: %{atom => String.t},
    output: %{atom => String.t},
  }

  @input_reg ~r{^in\d\d?$}
  @output_reg ~r{^out\d\d?$}

  defstruct [
    processor: NullProcessor,
    input: %{},
    output: %{}
  ]

  @spec to_spec(map) :: t | {:error, String.t}
  def to_spec(raw_spec) when is_map(raw_spec) do
    case Processors.fetch(raw_spec["processor"]) do
      :error -> {:error, "Invalid processor #{raw_spec["processor"]}"}
      {:ok, processor} ->
        %__MODULE__{
          processor: processor,
          input: to_inputs(raw_spec["input"]),
          output: to_outputs(raw_spec["output"]),
        }
    end
  end

  @spec put_processor(t, module) :: t
  def put_processor(%__MODULE__{} = spec, module) do
    %{spec | processor: module}
  end

  @spec get_processor(t) :: t
  def get_processor(%__MODULE__{processor: processor}), do: processor

  @spec put_input(t, atom, String.t) :: t
  def put_input(%__MODULE__{} = spec, key, input) do
    update_in spec.input, &Map.put(&1, key, input)
  end

  @spec get_input(t, atom) :: String.t
  def get_input(spec, input), do: spec.input[input]

  @spec put_output(t, atom, String.t) :: t
  def put_output(%__MODULE__{} = spec, key, output) do
    update_in spec.output, &Map.put(&1, key, output)
  end

  @spec get_output(t, atom) :: String.t
  def get_output(spec, output), do: spec.output[output]

  @doc """
    iex> Helmsman.Spec.to_inputs(%{"in1" => 1, "malice" => 2, "in123" => 3})
    %{in1: 1}
  """
  @spec to_inputs(map) :: map
  def to_inputs(inputs) do
    select_regex_keys(inputs, @input_reg)
  end

  @doc """
    iex> Helmsman.Spec.to_outputs(%{"out1234" => 1, "out10" => 2, "malice" => 3})
    %{out10: 2}
  """
  @spec to_outputs(map) :: map
  def to_outputs(inputs) do
    select_regex_keys(inputs, @output_reg)
  end

  @doc """
    iex> Helmsman.Spec.select_regex_keys(%{"abc" => 1, "bcd" => 2, "cde" => 3}, ~r{bc})
    %{abc: 1, bcd: 2}
  """
  def select_regex_keys(nil, regex), do: %{}
  def select_regex_keys(inputs, regex) when is_map(inputs) do
    Enum.reduce inputs, %{}, fn
      {key, val}, acc ->
        if key =~ regex do
          Map.put(acc, String.to_atom(key), val)
        else
          acc
        end
    end
  end
end
