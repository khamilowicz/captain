defmodule MapmakerTest do
  use ExUnit.Case, async: true
  doctest Mapmaker

  import Mapmaker.ProcessorsHelpers
  import Mapmaker.StructureHelpers

  alias Mapmaker.Structure
  setup [
    :init_processors,
    :add_one_to_one_processor,
    :add_one_to_two_processor,
    :add_one_to_many_processor,
    :add_many_to_one_processor,
    :configure_processors
  ]

  describe "Given valid structure json" do
    setup [:valid_json_structure]

    test "Mapmaker.parse converts JSON processors structure into pipeline", context do
      Poison.decode!(context.json_structure) # Check if valid JSON
      #TODO: Test it better
      assert {:ok, %Structure{} = _pipeline, %{inputs: inputs}} = Mapmaker.decode(context.json_structure)
      assert is_list(inputs)
    end

    test "Mapmaker.parse converts map processors structure into pipeline", context do
      processors = Poison.decode!(context.json_structure) # Check if valid JSON
      #TODO: Test it better
      assert {:ok, %Structure{} = _pipeline, %{inputs: inputs}} = Mapmaker.decode(processors)
      assert is_list(inputs)
    end

  end
end
