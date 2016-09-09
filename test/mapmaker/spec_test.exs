defmodule Mapmaker.SpecTest do
  use ExUnit.Case, async: true
  doctest Mapmaker.Spec

  import Mapmaker.SpecHelpers
  alias Mapmaker.Spec

  describe "Given valid raw processor spec" do
    setup [:one_to_one_raw_spec]

    test "Spec.to_spec casts it to %Spec{}", context do
      assert %Spec{
        processor: Mapmaker.Processors.OneToOne,
        input: %{
          in1: "a",
        },
        output: %{
          out1: "b"
        }
      } == Spec.to_spec(context.one_to_one_spec, %{"one.to.one" => Mapmaker.Processors.OneToOne})
    end
  end
end
