defmodule Mapmaker.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Mapmaker.{Pipeline, Structure, Runnable, Pipeline.Postprocess, Pipeline.Output}


  @spec run(Pipeline.t | Structure.t, map, list, map) :: {:ok, any} | {:error, String.t}
  def run(runnable, input, output \\ [], extra \\ %{})

  def run(%Structure{} = structure, input, output, extra) do
    pipeline_register = Pipeline.Register.from_structure(structure)
    main_pipeline = Pipeline.Register.main(pipeline_register)

    extra = Map.put(extra, :register, pipeline_register)

    run(main_pipeline, input, output, extra)
  end
  def run(%Pipeline{} = pipeline, input, output_specification, extra) do

    {executed_pipeline, result} = Runnable.run(pipeline, input, extra)

    case Pipeline.status(executed_pipeline) do
      :failed -> {:error, result}
      :done -> {:ok, process_result(result, output_specification, extra)}
    end
  end

  def process_result(result, output_specification, extra) do
    if Enum.empty?(output_specification) do
      result
    else
      do_process_result(result, output_specification, extra)
    end
  end

  def do_process_result(result, output_specification, extra) do
    for out <- output_specification, into: %{} do
      case Postprocess.run(result[Output.name(out)], Output.postprocess(out)) do
        {:ok, res} -> {Output.name(out), res}
        {:error, reason} -> {Output.name(out), %{error: reason}}
      end
    end
  end
end
