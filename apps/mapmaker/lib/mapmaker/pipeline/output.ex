defmodule Mapmaker.Pipeline.Output do
  defstruct [:name, :postprocess]

  def postprocess(output), do: output.postprocess
  def name(output), do: output.name
end
