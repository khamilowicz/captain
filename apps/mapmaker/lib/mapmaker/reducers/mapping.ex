defmodule Mapmaker.Reducers.Mapping do

  alias Mapmaker.{Runnable, Utils}
  alias Mapmaker.Pipeline.Register

  @derive [Mapmaker.Pipeable, Mapmaker.Runnable]

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

  @spec to_spec(map) :: %__MODULE__{}
  def to_spec(raw_spec) when is_map(raw_spec) do
    %__MODULE__{
      pipeline: raw_spec["pipeline"],
      input: raw_spec["input"],
      output: raw_spec["output"]
    }
  end

  def put_pipeline(map_spec, pipeline) do
    %{map_spec | pipeline: pipeline}
  end

  def pipeline(spec, input, extra) do
    cond do
      is_bitstring(spec.pipeline) -> Register.get(extra[:register], spec.pipeline)
      true -> spec.pipeline
    end
  end

  def run(spec, input, extra) do
    pipeline_input =
      spec.input
      |> Utils.input_joins(input)
      |> Map.get("inN")

    #TODO: Use new specs and pipeline to create new pipe
    {new_specs, outputs} = pipeline_input
              |> Enum.map(&Runnable.run(pipeline(spec, input, extra), &1, extra))
              |> Utils.transpose_tuples

    if Enum.any?(new_specs, &Runnable.failed?/1) do
      {Runnable.fail(spec), %{spec.output["outN"] => outputs}}
    else
      {Runnable.done(spec), %{spec.output["outN"] => outputs}}
    end
  end
end
