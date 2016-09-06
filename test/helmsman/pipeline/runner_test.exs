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

defmodule OneToVariable do
  def run(%{in1: in1} = input) do
    send self, {:processor_called, __MODULE__, input}
    %{outN: [%{out1: in1 <> "v"}, %{out1: in1 <> "v"}, %{out1: in1 <> "v"}] }
  end

end

defmodule Helmsman.Pipeline.RunnerTest do
  use ExUnit.Case, async: true

  doctest Helmsman.Pipeline.Runner

  import Helmsman.SpecHelpers

  alias Helmsman.{Pipeline, Spec}
  alias Helmsman.Pipeline.Runner

  describe "Given straight Pipeline" do
    setup [:one_to_one_spec]

    test "Runner.run/1 executes processors, passing arguments around", context do

      first_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "a") |> Spec.put_output(:out1, "b")
      second_spec = context.one_to_one_spec |> Spec.put_input(:in1, "b") |> Spec.put_output(:out1, "c")
      third_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "c") |> Spec.put_output(:out1, "d")

      specs = [
        first_spec,
        second_spec,
        third_spec
      ]

      straight_pipeline = Pipeline.to_pipeline(specs)

      assert {:ok, result} = Runner.run(straight_pipeline, %{"a" => "f"})
      assert_received {:processor_called, OneToOne, %{in1: "f"}}
      assert_received {:processor_called, OneToOne, %{in1: "fa"}}
      assert_received {:processor_called, OneToOne, %{in1: "faa"}}
      assert result["d"] == "faaa"
    end
  end

  describe "Given forked Pipeline" do
    setup [:one_to_one_spec, :one_to_two_spec, :two_to_one_spec]

    test "Runner.run/1 executes processors, passing arguments around", context do

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

    forked_pipeline = Pipeline.to_pipeline(specs)
    assert {:ok, result} = Runner.run(forked_pipeline, %{"a" => "f"})

    assert_received {:processor_called, OneToOne, %{in1: "f"}}
    assert_received {:processor_called, OneToTwo, %{in1: "fa"}}
    assert_received {:processor_called, OneToOne, %{in1: "fal"}}
    assert_received {:processor_called, OneToOne, %{in1: "far"}}
    assert_received {:processor_called, TwoToOne, %{in1: "fala", in2: "fara"}}
    assert %{"g" => "falafarac"} = result
    end
  end

  describe "Given variable output pipeline" do
    setup [:one_to_one_spec, :one_to_variable_spec, :map_reducer_spec]

    test "Runner.run/1 can map outputs of variable specs", context do
      first_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "a") |> Spec.put_output(:out1, "b")
      variable_spec = context.one_to_variable_spec
                      |> Spec.put_input(:in1, "b")
                      |> Spec.put_output(:outN, {"c", %{out1: "e"}})

      map_one_spec  = context.one_to_one_spec |> Spec.put_input(:in1, "e") |> Spec.put_output(:out1, "output")
      map_pipeline = Pipeline.to_pipeline([map_one_spec])

      map_proc = context.map_reducer_spec
                  |> Spec.put_input(:inN, "c")
                  |> Spec.put_output(:outN, "d")
                  |> Helmsman.Reducers.Mapping.put_pipeline(map_pipeline)

      specs = [
        first_spec,
        variable_spec,
        map_proc
      ]

      variable_pipeline = Pipeline.to_pipeline(specs)
      assert {:ok, result} = Runner.run(variable_pipeline, %{"a" => "f"})

      assert_received {:processor_called, OneToOne, %{in1: "f"}}
      assert_received {:processor_called, OneToVariable, %{in1: "fa"}}
      assert_received {:processor_called, OneToOne, %{in1: "fav"}}
      assert_received {:processor_called, OneToOne, %{in1: "fav"}}
      assert_received {:processor_called, OneToOne, %{in1: "fav"}}

      assert Enum.map(result["d"], &Map.get(&1, "output")) == ["fava", "fava", "fava"]
    end
  end
end

