defmodule Helmsman.Reducers.Mapping do

  alias Helmsman.{Runnable, Utils}

  @derive [Helmsman.Pipeable, Helmsman.Runnable]

  defstruct [
    pipeline: nil,
    status: :prepared,
    input: %{},
    output: %{}
  ]

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
    {Runnable.done(spec), %{spec.output[:outN] => outputs}}
  end
end
