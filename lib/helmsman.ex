defmodule Helmsman.Structure do
  defstruct [:inputs, :outputs, :pipelines]
end

defmodule Helmsman.Decoder.InputPipeline do
  defstruct [:name, :pipeline, :structure]
end

defimpl Poison.Decoder, for: Helmsman.Decoder.InputPipeline do
  alias Helmsman.Reducers.Mapping
  def decode(in_pipeline, _options) do
    specs = in_pipeline.structure |> Enum.map(&to_specs/1)
    pipeline = Helmsman.Pipeline.to_pipeline(specs)
    %{in_pipeline | pipeline: pipeline, structure: nil}
  end

  def to_specs(%{"processor" => "mapper"} = raw_spec) do
    Mapping.to_spec(raw_spec)
  end
  def to_specs(raw_spec), do: Helmsman.Spec.to_spec(raw_spec)
end

defmodule Helmsman do
  @moduledoc """
  Processor composer.

  Helmsman converts processor pipeline specification into pipeline.
  """

  alias Helmsman.{Pipeline, Structure, Spec}
  alias Helmsman.Decoder.InputPipeline

  def decode(json) do
    case Poison.decode(json, as: %Structure{pipelines: [%InputPipeline{pipeline: %Pipeline{specs: [%Spec{}]}}]}) do
      {:ok, structure} -> 
        {:ok, json} = Poison.decode(json)
        {:ok, structure, json["inputs"], json["outputs"]}
      {:error, reason} -> {:error, reason}
    end
  end
end

