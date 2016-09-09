defmodule Mapmaker.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Mapmaker.{Pipeline, Structure, Runnable}


  @spec run(Pipeline.t | Structure.t, map, map, map) :: {:ok, any} | {:error, String.t}
  def run(runnable, input, output \\ %{}, extra \\ %{})

  def run(%Structure{} = structure, input, output, extra) do
    pipeline_register = Pipeline.Register.from_structure(structure)
    main_pipeline = Pipeline.Register.main(pipeline_register)


    extra = Map.put(extra, :register, pipeline_register)

    run(main_pipeline, input, output, extra)
  end
  def run(%Pipeline{} = pipeline, input, _output, extra) do
    {executed_pipeline, result} = Runnable.run(pipeline, input, extra)

    case Pipeline.status(executed_pipeline) do
      :failed -> {:error, result}
      :done -> {:ok, result}
    end
  end
end
