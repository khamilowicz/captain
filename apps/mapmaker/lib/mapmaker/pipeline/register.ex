defmodule Mapmaker.Pipeline.Register do
  defstruct [:pipelines]

  alias Mapmaker.Pipeline.Register.Entry

  def from_structure(%{pipelines: pipelines}) when is_list(pipelines) do
    map_pipelines =
      pipelines
      |> Enum.map(&{&1.name, &1})
      |> Enum.into(%{})

    %__MODULE__{pipelines: map_pipelines}
  end

  def main(register) do
    case register.pipelines["main"] do
      nil -> throw("Malformed Structure")
      entry -> Entry.pipeline(entry)
    end
  end
  def get(nil, _name), do: nil
  def get(register, name) do
    Entry.pipeline(register.pipelines[name])
  end
end

defmodule Mapmaker.Pipeline.Register.Entry do
  defstruct [:name, :pipeline, :structure]

  def pipeline(entry), do: entry.pipeline
end

defimpl Poison.Decoder, for: Mapmaker.Pipeline.Register.Entry do
  alias Mapmaker.Reducers.Mapping
  def processor_register do
    Application.get_env(:mapmaker, :processors)
  end
  def decode(in_pipeline, _options) do
    specs = in_pipeline.structure |> Enum.map(&to_specs/1)
    pipeline = Mapmaker.Pipeline.to_pipeline(specs)
    %{in_pipeline | pipeline: pipeline, structure: nil}
  end

  def to_specs(%{"processor" => "mapper"} = raw_spec) do
    Mapping.to_spec(raw_spec)
  end
  def to_specs(raw_spec), do: Mapmaker.Spec.to_spec(raw_spec, processor_register)
end


