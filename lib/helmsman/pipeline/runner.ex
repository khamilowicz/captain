defmodule Helmsman.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Helmsman.{Pipeline, Runnable}

  @spec run(Pipeline.t, map) :: {:ok, any} | {:error, String.t}
  def run(pipeline, input) do
    current_pipeline =  Pipeline.for_inputs(pipeline, Map.keys(input))

    if Pipeline.empty?(current_pipeline) do
      {:ok, input}
    else
      new_input = Runnable.run(current_pipeline, input)
      new_pipeline = Pipeline.subtract(pipeline, current_pipeline)
      run(new_pipeline, new_input)
    end
  end
end
