defmodule Helmsman do
  @moduledoc """
  Processor composer.

  Helmsman converts processor pipeline specification into pipeline.
  """

  alias Helmsman.{Pipeline, Structure, Spec}
  alias Helmsman.Pipeline.Register.Entry

  def decode(json) do
    case Poison.decode(json, as: %Structure{pipelines: [%Entry{pipeline: %Pipeline{specs: [%Spec{}]}}]}) do
      {:ok, structure} ->
        {:ok, io} = Poison.decode(json, as: %Structure.IO{})
        {:ok, structure, io}
      {:error, reason} -> {:error, reason}
    end
  end
end

