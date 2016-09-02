defmodule Helmsman.ProcessorsTest do
  use ExUnit.Case, async: true
  doctest Helmsman.Processors

  import Helmsman.ProcessorsHelpers
  alias Helmsman.Processors

  describe "Given environment is configured" do
    setup [:init_processors, :add_one_to_one_processor, :configure_processors]

    test "Processors maps strings to configured processors" do
      assert Processors.fetch!("one.to.one") == Helmsman.Processors.OneToOne
    end

    test "Processors raises exception if processor is not configured" do
      assert_raise Processors.Undefined, fn ->  Processors.fetch!("unknown") end
    end
  end
end
