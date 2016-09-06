defmodule Helmsman.Reducers.Mapping do

  defstruct [
    pipeline: nil,
    input: %{},
    output: %{}
  ]

  def put_pipeline(map_spec, pipeline) do
    %{map_spec | pipeline: pipeline}
  end
end

defimpl Helmsman.Runnable, for: Helmsman.Reducers.Mapping do

  alias Helmsman.{Utils, Runnable}

  def run(spec, input) do

    pipeline_input =
      spec.input
      |> Utils.syllogism_of_maps(input)
      |> Map.get(:inN)

    result = Enum.map(pipeline_input, &Runnable.run(spec.pipeline, &1))
    %{spec.output[:outN] => result}
  end
end
