defmodule Helmsman.Pipeline.Runner do
  @moduledoc """

  Executes Pipeline.

  Directs inputs and outputs between processors, using rules from pipeline.
  """

  alias Helmsman.{Pipeline, Runnable}

  @spec run(Pipeline.t, map) :: {:ok, any} | {:error, String.t}
  def run(pipeline, input) do
    if Pipeline.empty?(pipeline) do
      {:ok, input}
    else
      {new_pipeline, new_input} = Runnable.run(pipeline, input)
      run(new_pipeline, new_input)
    end
  end
end
