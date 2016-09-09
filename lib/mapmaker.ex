defmodule Mapmaker do
  @moduledoc """
  Processor composer.

  Mapmaker converts processor pipeline specification into pipeline.
  """

  alias Mapmaker.{Pipeline, Structure, Spec}
  alias Mapmaker.Pipeline.Register.Entry

  defdelegate run(runnable, input, output, extra), to: Pipeline.Runner

  def decode(json) do
    case Poison.decode(json, as: %Structure{pipelines: [%Entry{pipeline: %Pipeline{specs: [%Spec{}]}}]}) do
      {:ok, structure} ->
        {:ok, io} = Poison.decode(json, as: %Structure.IO{})
        {:ok, structure, io}
      {:error, reason} -> {:error, reason}
    end
  end
end

