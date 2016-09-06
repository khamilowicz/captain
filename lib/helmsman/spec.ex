defmodule Helmsman.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct

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

  @type io_key :: String.t

  @input_reg ~r{^in\d\d?N?$}
  @output_reg ~r{^out\d\d?N?$}

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
  def put_processor(spec, module) do
    %{spec | processor: module}
  end

  @spec get_processor(t) :: t
  def get_processor(%{processor: processor}), do: processor

  @spec put_input(t, atom, io_key) :: t
  def put_input(spec, key, input) do
    put_in spec.input[key], input
  end

  @spec get_input(t, atom) :: io_key
  def get_input(spec, input), do: spec.input[input]

  @spec input_keys(t) :: [io_key]
  def input_keys(spec), do: Map.values(spec.input)

  @spec put_output(t, atom, io_key) :: t
  def put_output(spec, key, output) do
    put_in spec.output[key], output
  end

  @spec get_output(t, atom) :: io_key
  def get_output(spec, output), do: spec.output[output]

  @spec output_keys(t) :: [io_key]
  def output_keys(spec), do: Map.values(spec.output)

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
  def select_regex_keys(nil, _regex), do: %{}
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

defimpl Helmsman.Runnable, for: Helmsman.Spec do
  alias Helmsman.Utils

  def run(spec, input) do
    spec.input
    |> Utils.syllogism_of_maps(input)
    |> spec.processor.run
    |> Utils.remap_keys(spec.output)
  end
end
