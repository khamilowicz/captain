defmodule Helmsman.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct

  Examples

  iex> spec = %Helmsman.Spec{}
  iex> spec = Helmsman.Spec.put_processor(spec, MyProcessor)
  iex> Helmsman.Spec.get_processor(spec)
  MyProcessor
  iex> spec = Helmsman.Pipeable.put_input(spec, :in1, "a")
  iex> spec = Helmsman.Pipeable.put_output(spec, :out1, "b")
  iex> Helmsman.Pipeable.get_input(spec, :in1)
  "a"
  iex> Helmsman.Pipeable.get_output(spec, :out1)
  "b"
  """

  alias Helmsman.{Processors, Utils}

  @type t :: %{
    processor: module,
    input: %{atom => String.t},
    output: %{atom => String.t},
  }

  @input_reg ~r{^in\d\d?N?$}
  @output_reg ~r{^out\d\d?N?$}

  @derive [Helmsman.Pipeable]

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
    result =
      spec.input
      |> Utils.input_joins(input)
      |> spec.processor.run
      |> Utils.remap_keys(spec.output)
    {spec, result}
  end
end
