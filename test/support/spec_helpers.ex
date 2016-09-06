defmodule Helmsman.SpecHelpers do

  alias Helmsman.Spec
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
      |> Spec.put_input(:in1, "a")
      |> Spec.put_output(:out1, "b")

    {:ok, Map.put(context, :one_to_one_spec, spec)}
  end
  def one_to_two_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToTwo)
      |> Spec.put_input(:in1, "b")
      |> Spec.put_output(:out1, "c")
      |> Spec.put_output(:out2, "d")

    {:ok, Map.put(context, :one_to_two_spec, spec)}
  end
  def two_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(TwoToOne)
      |> Spec.put_input(:in1, "c")
      |> Spec.put_input(:in2, "d")
      |> Spec.put_output(:out2, "e")

    {:ok, Map.put(context, :two_to_one_spec, spec)}
  end
  def one_to_variable_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToVariable)
      |> Spec.put_input(:in1, "a")
      |> Spec.put_output(:outN, "b")

    {:ok, Map.put(context, :one_to_variable_spec, spec)}
  end
  def map_reducer_spec(context) do
    spec =
      %Mapping{}
      |> Spec.put_input(:inN, "a")
      |> Spec.put_output(:outN, "b")

    {:ok, Map.put(context, :map_reducer_spec, spec)}
  end

end
