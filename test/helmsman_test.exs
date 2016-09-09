defmodule HelmsmanTest do
  use ExUnit.Case, async: true
  doctest Helmsman

  import Helmsman.ProcessorsHelpers
  import Helmsman.StructureHelpers

  alias Helmsman.Structure
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

    test "Helmsman.parse converts JSON processors structure into pipeline", context do
      Poison.decode!(context.json_structure) # Check if valid JSON
      #TODO: Test it better
      assert {:ok, %Structure{} = _pipeline, %{input: %{"a" => "http://www.example.org"}}} = Helmsman.decode(context.json_structure)
    end

  end
end
