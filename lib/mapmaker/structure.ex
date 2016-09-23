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
    input =
      value.inputs
      |> Enum.map(&{&1["name"], &1["value"]})
      |> Enum.into(%{})

    output = Enum.map(value.outputs, &%Mapmaker.Pipeline.Output{name: &1["name"], postprocess: &1["postproc"]})

    %{value | input: input, output: output}
  end
end
