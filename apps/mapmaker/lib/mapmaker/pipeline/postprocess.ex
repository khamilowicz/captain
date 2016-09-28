defmodule Mapmaker.Pipeline.Process do

  @spec run(map, String.t, map) :: {:ok, map} | {:error, any}
  def run(input, postprocessor, extra \\ %{})
  def run(input, nil, extra), do: {:ok, input}
  def run(input, postprocessor, extra) when is_bitstring(postprocessor) do
    case Map.fetch(postprocessors, postprocessor) do
      {:ok, processor} -> processor.run(input, extra)
      :error -> {:error, "Postprocessor #{postprocessor} not found"}
    end
  end
  def run(input, postprocessor, extra) when is_map(postprocessor) do
    Enum.reduce postprocessor, {:ok, input}, fn
      ({name, args}, {:ok, inp}) -> run(inp, name, Map.merge(args, extra))
      ({name, args}, {:error, reason}) -> {:error, reason}
    end
  end

  def postprocessors do
    Application.get_env(:mapmaker, :postprocessors, %{})
  end
end
