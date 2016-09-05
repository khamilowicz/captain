defmodule Helmsman.SpecTest do
  use ExUnit.Case, async: true
  doctest Helmsman.Spec

  import Helmsman.SpecHelpers
  alias Helmsman.Spec

  describe "Given valid raw processor spec" do
    setup [:one_to_one_raw_spec]

    test "Spec.to_spec casts it to %Spec{}", context do
      assert %Spec{
        processor: Helmsman.Processors.OneToOne,
        input: %{
          in1: "a",
        },
        output: %{
          out1: "b"
        }
      } == Spec.to_spec(context.one_to_one_spec)
    end
  end
end
