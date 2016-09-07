defmodule Helmsman.PipelineTest do
  use ExUnit.Case, async: true

  import Helmsman.SpecHelpers

  alias Helmsman.{Pipeline, Pipeable}

  doctest Helmsman.Pipeline

  describe "Given valid Spec pipeline" do
    setup [:one_to_one_spec, :one_to_two_spec, :two_to_one_spec, :prepare_pipeline_spec]

    test "Pipeline.to_pipeline prepares pipeline tree", context do
      assert %Pipeline{specs: context.pipeline_spec } == Pipeline.to_pipeline(context.pipeline_spec)
    end
  end

  describe "Given pipeline" do
    setup [:one_to_one_spec, :one_to_two_spec, :two_to_one_spec, :prepare_pipeline_spec, :prepare_pipeline]

    test "Pipeline.for_input takes Pipeline and input key and finds specs for given input", context do
      assert [a_spec] = Pipeline.for_input(context.pipeline, "a")
      assert [b_spec] = Pipeline.for_input(context.pipeline, "b")

      assert Pipeable.get_input(a_spec, :in1) == "a"
      assert Pipeable.get_input(b_spec, :in1) == "b"
    end
  end

  defp prepare_pipeline(context) do
    pipeline = Pipeline.to_pipeline(context.pipeline_spec)

    {:ok, Map.put(context, :pipeline, pipeline)}
  end

  defp prepare_pipeline_spec(context) do
    pipeline = [
      context.one_to_one_spec,
      context.one_to_two_spec,
      context.two_to_one_spec,
    ]
    {:ok, Map.put(context, :pipeline_spec, pipeline)}
  end
end
