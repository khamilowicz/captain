defmodule Helmsman.Reducers.Mapping do

  @derive [Helmsman.Pipeable]

  defstruct [
    pipeline: nil,
    status: :prepared,
    input: %{},
    output: %{}
  ]

  def put_pipeline(map_spec, pipeline) do
    %{map_spec | pipeline: pipeline}
  end
end

defimpl Helmsman.Runnable, for: Helmsman.Reducers.Mapping do

  alias Helmsman.{Utils, Runnable}
  def failed?(spec), do: spec.status == :failed
  def done?(spec), do: spec.status == :done
  def required?(spec), do: spec.required

  def fail(spec) do
    %{spec | status: :fail}
  end

  def done(spec) do
    %{spec | status: :done}
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
    {done(spec), %{spec.output[:outN] => outputs}}
  end
end
