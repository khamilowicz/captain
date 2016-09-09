defmodule Mapmaker.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct

  Examples

  iex> spec = %Mapmaker.Spec{}
  iex> spec = Mapmaker.Spec.put_processor(spec, MyProcessor)
  iex> Mapmaker.Spec.get_processor(spec)
  MyProcessor
  iex> spec = Mapmaker.Pipeable.put_input(spec, :in1, "a")
  iex> spec = Mapmaker.Pipeable.put_output(spec, :out1, "b")
  iex> Mapmaker.Pipeable.get_input(spec, :in1)
  "a"
  iex> Mapmaker.Pipeable.get_output(spec, :out1)
  "b"
  """

  alias Mapmaker.{Utils, Runnable}

  @type status :: :prepared | :failed | :done

  @type t :: %{
    processor: module,
    required: boolean,
    status: status,
    input: %{atom => String.t},
    output: %{atom => String.t},
  }

  @input_reg ~r{^in(\d\d?|N)$}
  @output_reg ~r{^out(\d\d?|N)$}

  @derive [Mapmaker.Pipeable, Mapmaker.Runnable]

  defstruct [
    processor: NullProcessor,
    required: false,
    status: :prepared,
    input: %{},
    output: %{}
  ]

  @spec to_spec(map, module) :: t | {:error, String.t}
  def to_spec(raw_spec, processors) when is_map(raw_spec) do
    case processors[raw_spec["processor"]] do
      nil -> {:error, "Invalid processor #{raw_spec["processor"]}"}
      processor ->
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

  @spec get_processor(t) :: module
  def get_processor(%{processor: processor}), do: processor

  @doc """
  iex> Mapmaker.Spec.to_inputs(%{"in1" => 1, "malice" => 2, "in123" => 3, "inN" => %{"key" => "hello", "mappings" => %{"in1" => "a"}}})
  %{in1: 1, inN: %{key: "hello", mappings: %{in1: "a"}}}
  """
  @spec to_inputs(map) :: map
  def to_inputs(inputs) do
    Utils.select_regex_keys(inputs, @input_reg)
    |> Enum.map(fn
        {:inN, val} -> {:inN, to_n_mapping(val, &to_inputs/1)}
        other -> other
    end)
    |> Enum.into(%{})
  end

  @doc """
  iex> Mapmaker.Spec.to_outputs(%{"out1234" => 1, "out10" => 2, "malice" => 3, "outN" => %{"key" => "hello", "mappings" => %{"out1" => "a"}}})
  %{out10: 2, outN: %{key: "hello", mappings: %{out1: "a"}}}
  """
  @spec to_outputs(map) :: map
  def to_outputs(inputs) do
    Utils.select_regex_keys(inputs, @output_reg)
    |> Enum.map(fn
        {:outN, val} -> {:outN, to_n_mapping(val, &to_outputs/1)}
        other -> other
    end)
    |> Enum.into(%{})
  end

  def to_n_mapping(%{"key" => key, "mappings" => mappings}, mapping_parser) do
    %{key: key, mappings: mapping_parser.(mappings)}
  end

  def run(spec, input, extra) do
    try do
      result =
        spec.input
        |> Utils.input_joins(input)
        |> get_processor(spec).run(extra)
        |> Utils.remap_keys(spec.output)
      {Runnable.done(spec), result}
    catch
      any -> {Runnable.fail(spec), %{error: any}}
    end
  end
end
