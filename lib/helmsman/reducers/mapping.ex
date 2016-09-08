defmodule Helmsman.Reducers.Mapping do

  alias Helmsman.{Runnable, Utils}

  @derive [Helmsman.Pipeable, Helmsman.Runnable, Poison.Decoder]

  @input_reg ~r{^inN$}
  @output_reg ~r{^outN$}

  @type status :: :prepared | :running | :done | :failed

  @type t :: %{
    pipeline: Runnable.t,
    status: status,
    required: boolean,
    input: map,
    output: map
  }

  defstruct [
    pipeline: nil,
    status: :prepared,
    required: false,
    input: %{},
    output: %{}
  ]

  @spec to_spec(map) :: t | {:error, String.t}
  def to_spec(raw_spec) when is_map(raw_spec) do
    %__MODULE__{
      pipeline: raw_spec["pipeline"],
      input: to_inputs(raw_spec["input"]),
      output: to_outputs(raw_spec["output"])
    }
  end

  def to_inputs(inputs) do
    Utils.select_regex_keys(inputs, @input_reg)
  end

  def to_outputs(inputs) do
    Utils.select_regex_keys(inputs, @output_reg)
  end

  def put_pipeline(map_spec, pipeline) do
    %{map_spec | pipeline: pipeline}
  end

  def run(spec, input) do
    pipeline_input =
      spec.input
      |> Utils.input_joins(input)
      |> Map.get(:inN)

    #TODO: Use new specs and pipeline to create new pipe
    {new_specs, outputs} = pipeline_input
              |> Enum.map(&Runnable.run(spec.pipeline, &1))
              |> Utils.transpose_tuples

    if Enum.any?(new_specs, &Runnable.failed?/1) do
      {Runnable.fail(spec), %{spec.output[:outN] => outputs}}
    else
      {Runnable.done(spec), %{spec.output[:outN] => outputs}}
    end
  end
end
