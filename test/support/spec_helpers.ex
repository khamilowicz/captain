defmodule Helmsman.SpecHelpers do

  alias Helmsman.{Spec, Pipeable}
  alias Helmsman.Reducers.Mapping

  def one_to_one_raw_spec(context) do
    raw_spec = %{
      "processor" => "one.to.one",
      "input" => %{"in1" => "a"},
      "output" => %{"out1" => "b"},
    }
    {:ok, Map.put(context, :one_to_one_spec, raw_spec)}
  end

  def one_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToOne)
      |> Pipeable.put_input(:in1, "a")
      |> Pipeable.put_output(:out1, "b")

    {:ok, Map.put(context, :one_to_one_spec, spec)}
  end

  def one_to_two_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToTwo)
      |> Pipeable.put_input(:in1, "b")
      |> Pipeable.put_output(:out1, "c")
      |> Pipeable.put_output(:out2, "d")

    {:ok, Map.put(context, :one_to_two_spec, spec)}
  end

  def two_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(TwoToOne)
      |> Pipeable.put_input(:in1, "c")
      |> Pipeable.put_input(:in2, "d")
      |> Pipeable.put_output(:out2, "e")

    {:ok, Map.put(context, :two_to_one_spec, spec)}
  end

  def one_to_variable_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToVariable)
      |> Pipeable.put_input(:in1, "a")
      |> Pipeable.put_output(:outN, "b")

    {:ok, Map.put(context, :one_to_variable_spec, spec)}
  end

  def variable_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(VariableToOne)
      |> Pipeable.put_input(:inN, "a")
      |> Pipeable.put_output(:out1, "b")

    {:ok, Map.put(context, :variable_to_one_spec, spec)}
  end

  def map_reducer_spec(context) do
    spec =
      %Mapping{}
      |> Pipeable.put_input(:inN, "a")
      |> Pipeable.put_output(:outN, "b")

    {:ok, Map.put(context, :map_reducer_spec, spec)}
  end

end
