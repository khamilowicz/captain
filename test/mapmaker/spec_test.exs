defmodule Mapmaker.SpecTest do
  use ExUnit.Case, async: true
  doctest Mapmaker.Spec

  import Mapmaker.SpecHelpers
  alias Mapmaker.Spec

  defmodule OneToOne do
    def run(input, extra) do
      send self, {:processor_called, __MODULE__, input, extra}
      {:ok, %{out1: "one"}}
    end
  end

  describe "Given valid raw processor spec" do
    setup [:one_to_one_raw_spec]

    setup(context) do
      converted_spec = Spec.to_spec(context.one_to_one_spec, %{"one.to.one" => OneToOne})
      {:ok, put_in(context, [:spec], converted_spec)}
    end

    test "Spec.to_spec casts it to %Spec{}", context do
      assert %Spec{
        processor: {OneToOne, "one.to.one"},
        input: %{
          in1: "a",
        },
        output: %{
          out1: "b"
        }
      } == context.spec
    end

    test "Spec.run/3 runs given processor", context do
      assert {%Spec{}, %{"b" => "one"}} = Spec.run(context.spec, %{in1: 1}, %{extra: true})
      assert_received {:processor_called, Mapmaker.SpecTest.OneToOne, %{in1: nil}, %{:extra => true, processor: "one.to.one"}}
    end
  end
end
