defmodule HelmsmanTest do
  use ExUnit.Case, async: true
  doctest Helmsman

  import Helmsman.ProcessorsHelpers

  alias Helmsman.Structure
  setup [
    :init_processors,
    :add_one_to_one_processor,
    :add_one_to_two_processor,
    :add_one_to_many_processor,
    :add_many_to_one_processor,
    :configure_processors
  ]

  test "Helmsman.parse converts JSON processors structure into pipeline" do
    pipeline_structure = """
    {
      "inputs": [{
        "value": "http://www.example.org",
        "name": "a",
        "preproc": "download"
      }],
      "outputs": [{
        "name": "h",
        "postproc": "upload"
      }],
      "pipelines": [
      {
        "name": "main",
        "structure": [
          {"processor": "one.to.one", "input": {"in1": "a"}, "output": {"out1": "b"}, "required": true},
          {"processor": "one.to.one", "input": {"in1": "b"}, "output": {"out1": "c"}, "required": true},
          {"processor": "one.to.two", "input": {"in1": "c"}, "output": {"out1": "d1", "out2": "d2"}, "required": true},
          {"processor": "one.to.many", "input": {"in1": "d1"}, "output": {"outN": "manyOut", "out1": "e"}, "required": true},
          {"processor": "mapper", "pipeline": "mapPipeline", "input": {"inN": "manyOut"}, "output": {"outN": "manyOut2"}, "required": true},
          {"processor": "many.to.one", "input": {"inN": "manyOut2"}, "output": {"out1": "h"}, "required": true}
        ]
      },
      {
        "name": "mapPipeline",
        "structure": [
            {"processor": "one.to.one", "input": {"in1": "e"}, "output": {"out1": "f"}, "required": true},
            {"processor": "one.to.one", "input": {"in1": "f"}, "output": {"out1": "g"}, "required": true}
          ]
        }
      ]
    }
    """

    Poison.decode!(pipeline_structure) # Check if valid JSON
    #TODO: Test it better
    assert {:ok, %Structure{} = _pipeline, _inputs, _outputs} = Helmsman.decode(pipeline_structure)
  end

end
