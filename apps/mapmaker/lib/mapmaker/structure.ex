defmodule Mapmaker.Structure do
  @type t :: %__MODULE__{}
  defstruct [:inputs, :outputs, :pipelines]
  alias Mapmaker.Pipeline.Register

  def main_pipeline(structure) do
    Register.get(structure, "main")
  end

  defmodule IO do
    defstruct [inputs: [], outputs: [], input: %{}, output: %{}]
  end
end

defimpl Poison.Decoder, for: Mapmaker.Structure.IO do
  def decode(value, _options) do
    input = Enum.map(value.inputs, &%Mapmaker.Pipeline.InOut{name: &1["name"], value: &1["value"], process: &1["preproc"]})
    output = Enum.map(value.outputs, &%Mapmaker.Pipeline.InOut{name: &1["name"], process: &1["postproc"]})

    %{value | input: input, output: output}
  end
end
