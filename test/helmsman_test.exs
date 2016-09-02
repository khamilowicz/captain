defmodule HelmsmanTest do
  use ExUnit.Case
  doctest Helmsman
  setup do: {:ok, %{processors: %{}}}

  describe "Given environment is configured" do
    setup [:add_one_to_one_processor, :configure_processors]

    test "Helmsman maps strings to processors" do
      processor = "one.to.one"
      assert Helmsman.processor(processor) == Helmsman.Processors.OneToOne
    end
  end

  defp add_one_to_one_processor(context) do
    {:ok, put_in(context.processors["one.to.one"], Helmsman.Processors.OneToOne)}
  end

  defp configure_processors(context) do
    Application.put_env(Helmsman, :processors, context.processors)
    :ok
  end
end
