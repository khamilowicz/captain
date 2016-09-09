defmodule Helmsman.StructureHelpers do

  def valid_json_structure(context) do
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
            {"processor": "one.to.variable", "input": {"in1": "d1"}, "output": {"outN": {"key": "manyOut", "mappings": {"out1": "e"}}}, "required": true},
            {"processor": "mapper", "pipeline": "mapPipeline", "input": {"inN": "manyOut"}, "output": {"outN": "manyOut2"}, "required": true},
            {"processor": "variable.to.one", "input": {"inN": {"key": "manyOut2", "mappings": {"in1": "g"}}}, "output": {"out1": "h"}, "required": true}
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

      {:ok, Map.put(context, :json_structure, pipeline_structure)}
    end

end
