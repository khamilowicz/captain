defmodule Helmsman.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Helmsman.{Pipeline, Structure, Pipeline}


  @spec run(Pipeline.t | Structure.t, map, map) :: {:ok, any} | {:error, String.t}
  def run(runnable, input, output \\ %{})
  def run(%Structure{} = structure, input, output) do
    pipeline_register = Pipeline.Register.from_structure(structure)
    main_pipeline = Pipeline.Register.main(pipeline_register)

    input = Map.put(input, "_register", pipeline_register)

    run(main_pipeline, input, output)
  end
  def run(%Pipeline{} = pipeline, input, _output) do
    {executed_pipeline, result} = Pipeline.run(pipeline, input)

    case Pipeline.status(executed_pipeline) do
      :failed -> {:error, result}
      :done -> {:ok, result}
    end
  end
end
