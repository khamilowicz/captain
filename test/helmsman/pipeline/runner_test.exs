defmodule OneToOne do

  def run(%{in1: in1} = input) do
    send self, {:processor_called, __MODULE__, input}
    %{out1: in1 <> "a"}
  end
end

defmodule Helmsman.Pipeline.RunnerTest do
  use ExUnit.Case, async: true

  doctest Helmsman.Pipeline.Runner

  import Helmsman.SpecHelpers

  alias Helmsman.{Pipeline, Spec}
  alias Helmsman.Pipeline.Runner

  describe "Given straight Pipeline" do
    setup [:one_to_one_spec, :prepare_straight_pipeline]

    test "Runner.run/1 executes processors, passing arguments around", context do
      assert {:ok, _result} = Runner.run(context.straight_pipeline, %{"a" => "f"})
      assert_received {:processor_called, OneToOne, %{in1: "f"}}
      assert_received {:processor_called, OneToOne, %{in1: "fa"}}
      assert_received {:processor_called, OneToOne, %{in1: "faa"}}
    end
  end

  def prepare_straight_pipeline(context) do
    first_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "a") |> Spec.put_output(:out1, "b")
    second_spec = context.one_to_one_spec |> Spec.put_input(:in1, "b") |> Spec.put_output(:out1, "c")
    third_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "c") |> Spec.put_output(:out1, "d")

    specs = [
      first_spec,
      second_spec,
      third_spec
    ]

    {:ok, Map.put(context, :straight_pipeline, Pipeline.to_pipeline(specs))}
  end

end
