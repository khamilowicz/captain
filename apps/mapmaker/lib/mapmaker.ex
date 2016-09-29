defmodule Mapmaker do
  @moduledoc """
  Processor composer.

  Mapmaker converts processor pipeline specification into pipeline.
  """

  alias Mapmaker.{Pipeline, Structure, Spec}
  alias Mapmaker.Pipeline.Register.Entry

  defdelegate run(runnable, input, output, extra), to: Pipeline.Runner

  def decode(json) when is_bitstring(json) do
    case Poison.decode(json, as: %Structure{pipelines: [%Entry{pipeline: %Pipeline{specs: [%Spec{}]}}]}) do
      {:ok, structure} ->
        {:ok, io} = Poison.decode(json, as: %Structure.IO{})
        {:ok, structure, io}
      {:error, reason} -> {:error, reason}
    end
  end

  def decode(map) when is_map(map) do
    case Poison.Decode.decode(map, as: %Structure{pipelines: [%Entry{pipeline: %Pipeline{specs: [%Spec{}]}}]}) do
      %Structure{} = structure ->
        %Structure.IO{} = io = Poison.Decode.decode(map, as: %Structure.IO{})
        {:ok, structure, io}
      reason -> {:error, reason}
    end
  end
end

