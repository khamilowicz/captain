defmodule Helmsman.SpecTest do
  use ExUnit.Case, async: true
  doctest Helmsman.Spec
  alias Helmsman.Spec

  describe "Given valid raw processor spec" do
    setup [:one_to_one_spec]

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

  defp one_to_one_spec(context) do
    raw_spec = %{
      "processor" => "one.to.one",
      "input" => %{"in1" => "a"},
      "output" => %{"out1" => "b"},
    }
    {:ok, Map.put(context, :one_to_one_spec, raw_spec)}
  end

end
