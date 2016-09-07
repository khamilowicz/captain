defmodule Helmsman.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Helmsman.Pipeline

  @spec run(Pipeline.t, map) :: {:ok, any} | {:error, String.t}
  def run(pipeline, input) do
    {executed_pipeline, result} = Pipeline.run(pipeline, input)

    case Pipeline.status(executed_pipeline) do
      :failed -> {:error, result}
      :done -> {:ok, result}
    end
  end
end
