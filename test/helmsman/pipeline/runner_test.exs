defmodule OneToOne do

  def run(%{in1: in1} = input) do
    send self, {:processor_called, __MODULE__, input}
    %{out1: in1 <> "a"}
  end
end

defmodule OneToTwo do

  def run(%{in1: in1} = input) do
    send self, {:processor_called, __MODULE__, input}
    %{out1: in1 <> "l", out2: in1 <> "r"}
  end
end

defmodule TwoToOne do
  def run(%{in1: in1, in2: in2} = input) do
    send self, {:processor_called, __MODULE__, input}
    %{out1: in1 <> in2 <> "c"}
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
      assert {:ok, result} = Runner.run(context.straight_pipeline, %{"a" => "f"})
      assert_received {:processor_called, OneToOne, %{in1: "f"}}
      assert_received {:processor_called, OneToOne, %{in1: "fa"}}
      assert_received {:processor_called, OneToOne, %{in1: "faa"}}
      assert result["d"] == "faaa"
    end
  end

  describe "Given forked Pipeline" do
    setup [:one_to_one_spec, :one_to_two_spec, :two_to_one_spec, :prepare_forked_pipeline]

    test "Runner.run/1 executes processors, passing arguments around", context do
      assert {:ok, result} = Runner.run(context.forked_pipeline, %{"a" => "f"})

      assert_received {:processor_called, OneToOne, %{in1: "f"}}
      assert_received {:processor_called, OneToTwo, %{in1: "fa"}}
      assert_received {:processor_called, OneToOne, %{in1: "fal"}}
      assert_received {:processor_called, OneToOne, %{in1: "far"}}
      assert_received {:processor_called, TwoToOne, %{in1: "fala", in2: "fara"}}
      assert %{"g" => "falafarac"} = result
    end
  end

  ### Setup

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

  def prepare_forked_pipeline(context) do
    first_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "a") |> Spec.put_output(:out1, "b")
    forking_spec = context.one_to_two_spec 
                    |> Spec.put_input(:in1, "b")
                    |> Spec.put_output(:out1, "c")
                    |> Spec.put_output(:out2, "d")

    left_spec = context.one_to_one_spec |> Spec.put_input(:in1, "c") |> Spec.put_output(:out1, "e")
    right_spec = context.one_to_one_spec |> Spec.put_input(:in1, "d") |> Spec.put_output(:out1, "f")

    converging_spec = context.two_to_one_spec
                      |> Spec.put_input(:in1, "e")
                      |> Spec.put_input(:in2, "f")
                      |> Spec.put_output(:out1, "g")

    specs = [
      first_spec,
      forking_spec,
      left_spec,
      right_spec,
      converging_spec
    ]

    {:ok, Map.put(context, :forked_pipeline, Pipeline.to_pipeline(specs))}
  end

end
