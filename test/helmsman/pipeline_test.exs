defmodule Helmsman.PipelineTest do
  use ExUnit.Case, async: true

  doctest Helmsman.Pipeline

  alias Helmsman.Spec
  alias Helmsman.Pipeline

  describe "Given valid Spec pipeline" do
    setup [:one_to_one_spec, :one_to_two_spec, :two_to_one_spec, :prepare_pipeline_spec]

    test "Pipeline.to_pipeline prepares pipeline tree", context do
      assert %Pipeline{specs: context.pipeline_spec } == Pipeline.to_pipeline(context.pipeline_spec)
    end

  end

  defp prepare_pipeline_spec(context) do
    pipeline = [
      context.one_to_one_spec,
      context.one_to_two_spec,
      context.two_to_one_spec,
    ]
    {:ok, Map.put(context, :pipeline_spec, pipeline)}
  end

  defp one_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToOne)
      |> Spec.put_input(:in1, "a")
      |> Spec.put_output(:out1, "b")

    {:ok, Map.put(context, :one_to_one_spec, spec)}
  end
  defp one_to_two_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToTwo)
      |> Spec.put_input(:in1, "b")
      |> Spec.put_output(:out1, "c")
      |> Spec.put_output(:out2, "d")

    {:ok, Map.put(context, :one_to_two_spec, spec)}
  end
  defp two_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(TwoToOne)
      |> Spec.put_input(:in1, "c")
      |> Spec.put_input(:in2, "d")
      |> Spec.put_output(:out2, "e")

    {:ok, Map.put(context, :two_to_one_spec, spec)}
  end

end
