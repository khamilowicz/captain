defmodule Helmsman.Structure do
  @type t :: %__MODULE__{}
  defstruct [:inputs, :outputs, :pipelines]
  alias Helmsman.Pipeline.Register

  def main_pipeline(structure) do
    Register.get(structure, "main")
  end

  defmodule IO do
    defstruct [inputs: [], outputs: [], input: %{}, output: %{}]
  end
end

defimpl Poison.Decoder, for: Helmsman.Structure.IO do
  def decode(value, _options) do
    input =
      value.inputs
      |> Enum.map(&{&1["name"], &1["value"]})
      |> Enum.into(%{})

    output =
      value.outputs
      |> Enum.map(&{&1["name"], &1["value"]})
      |> Enum.into(%{})

    %{value | input: input, output: output}
  end
end
