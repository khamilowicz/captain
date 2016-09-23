defmodule Mapmaker.Pipeline.Postprocess do

  @spec run(map, String.t) :: {:ok, map} | {:error, any}
  def run(input, nil), do: {:ok, input}
  def run(input, postprocessor) do
    case Map.fetch(postprocessors, postprocessor) do
      {:ok, processor} -> processor.run(input)
      :error -> {:error, "Postprocessor #{postprocessor} not found"}
    end
  end

  def postprocessors do
    Application.get_env(:mapmaker, :postprocessors, %{})
  end
end
