defmodule Helmsman.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Helmsman.{Pipeline, Spec}

  @spec run(Pipeline.t, map) :: {:ok, any} | {:error, String.t}
  def run(pipeline, input) do
    case Pipeline.for_inputs(pipeline, Map.keys(input)) do
      [] -> {:ok, input}
      specs ->
        new_input = do_run(specs, input)
        new_pipeline = Pipeline.remove(pipeline, specs)
        run(new_pipeline, new_input)
    end
  end

  def do_run(specs, input) do
    specs
    |> Enum.map(&Spec.run(&1, input))
    |> Enum.reduce(input, &Map.merge/2)
  end
end
