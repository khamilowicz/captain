defmodule Mapmaker.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Mapmaker.{Pipeline, Structure, Runnable, Pipeline.Process, Pipeline.InOut}


  @spec run(Pipeline.t | Structure.t, map, list, map) :: {:ok, any} | {:error, String.t}
  def run(runnable, input, output \\ [], extra \\ %{})

  def run(%Structure{} = structure, input, output, extra) do
    pipeline_register = Pipeline.Register.from_structure(structure)
    main_pipeline = Pipeline.Register.main(pipeline_register)

    extra = Map.put(extra, :register, pipeline_register)

    run(main_pipeline, input, output, extra)
  end
  def run(%Pipeline{} = pipeline, input, output_specification, extra) do
    input = process_input(input, extra)
    {executed_pipeline, result} = Runnable.run(pipeline, input, extra)

    case Pipeline.status(executed_pipeline) do
      :failed -> {:error, result}
      :done -> {:ok, process_result(result, output_specification, extra)}
    end
  end

  def process_input(input, _extra) when is_map(input), do: input
  def process_input(input, extra) do
    for inp <- input, into: %{} do
      case Process.run(InOut.value(inp), InOut.process(inp), extra) do
        {:ok, res} -> {InOut.name(inp), res}
        {:error, reason} -> {InOut.name(inp), %{error: reason}}
      end
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
      case Process.run(result[InOut.name(out)], InOut.process(out), extra) do
        {:ok, res} -> {InOut.name(out), res}
        {:error, reason} -> {InOut.name(out), %{error: reason}}
      end
    end
  end
end
