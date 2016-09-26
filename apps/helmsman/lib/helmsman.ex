defmodule Helmsman do
  @moduledoc """
  Helmsman sails you through the seas of processors.

  Using Mapmaker structure runs asynchronous jobs (processors), sending and receiving data
  from services.

  Currently supports DBus connections.

  ## Examples

    {:ok, helmsman} = Helmsman.read(json: "mapmaker structure")
    task = Helmsman.run(helmsman)

    :running = Helmsman.result(task)
    # Helmsman runs tasks, passing results around, calling processing nodes over dbus
    # ... some time later

    {:ok, %{result: "result of processing"}} = Helmsman.result(task)

  ## Structure

  Structure in essence is directed graph. Helmsman uses Mapmaker for schema format and running.
  Valid Mapmaker structure json schema is:

		{
			"inputs": [{
				"value": "stereo.mp3",
				"name": "file",
				"preproc": "download"
			},
			{
				"name": "output_file",
				"preproc": "generate"
			}
			],
			"outputs": [{
				"name": "output",
				"postproc": "to_json"
			}],
			"pipelines": [
				{
					"name": "main",
					"structure": [
						{"processor": "format", "input": {"INPUT": "file"}, "output": {"OUTPUT": "format_output"}, "required": true},
						{"processor": "stereo-reverse", "input": {"INPUT": "format_output"}, "output": {"OUTPUT": "reversed"}, "required": true},
						{"processor": "format", "input": {"INPUT": "reversed"}, "output": {"OUTPUT": "format1"}, "required": true},
						{"processor": "format", "input": {"INPUT": "reversed"}, "output": {"OUTPUT": "format2"}, "required": true},
						{"processor": "stereo-to-dual-mono", "input": {"INPUT": "format1"}, "output": {"OUTPUT_LEFT_CHANNEL": "left_channel", "OUTPUT_RIGHT_CHANNEL": "right_channel"}, "required": true},
						{"processor": "dual-mono-to-stereo", "input": {"INPUT_LEFT_CHANNEL": "left_channel", "INPUT_RIGHT_CHANNEL": "right_channel"}, "output": {"OUTPUT": "output"}, "required": true}
					]
				}
			]
		}

  Which runs as:


                                                                                         /> chanl \
   "stereo.mp3" -> download -> format -> stereo-reverse -> format -> stereo-to-dual-mono           > dual-mono-to-stereo
                                                        \> format                        \> chanr /

  Each processor takes input from labeled output and returns labeled value.

   - first "inputs" are converted into labels ("file" label describes "stereo.mp3" file, which is downloaded before processing.
   - then "format" processors takes "file" value (file path) and passes it to format processor, which outputs result to label "format_output
   - then "stereo-reverse" takes as INPUT value from "format_output", runs "stereo-reverse" and outputs result to label "reversed"
   - then second "format" takes "reversed" ...
   - etc.

   The result of running processors should be explicitly stated in "outputs" key.

   ## Processors

   Processor is module, which implements method run(inputs_map, extra_map) and returns:
    - tuples {:ok, outputs_map} or {:error, anything}.
    - Task, which eventually returns aforementioned values

   Inputs map is map specified in structure. So in case of first "stereo-reverse", input map will contain: 

			%{
				 "INPUT" => "value of format processing"
			}

    Outputs map should contain values of keys specified in structure as outputs. So successfull run of "stereo-to-dual-mono"
    should return:

			%{
				"OUTPUT_LEFT_CHANNEL" => "value we wish to pass further",
				"OUTPUT_RIGHT_CHANNEL" => "another value"
			}

   Extra map contains:
   - :processor -> Processor string identifier. Useful for multipurpose processors.
   - :output - map of outputs specified in structure schema

   ## Configuration

    Mappings between strings and modules can be configured in config files:

       config :mapmaker, :processors, %{
          "format" => MyApplication.Processors.Format
          "stereo-to-dual-mono" => MyApplication.Processors.StereoToDualMono,
					"any" => MyApplication.Processors.DoAllOtherStuff
				}

    ## Connection

      Helmsman is Radiokit API specific. Processor.start_processing sends input to configured hosts via tcp/dbus.

    ## Configuration
    
    Config file location can be configured with in config.exs
      config :helmsman, :processors, [
        config: "path/to/config.yml"
        ]

    You can provide your own connection, with:
      config :helmsman, :connection_provider, MyApp.MyConnection

    # TODO: Expand
    Connection provider should understand methods:
      - send_message(connection_pid, {message: {processor_name, random_string, input_map}, identifier: random_string}
      - connect(connection_options_map)
      - disconnect(connection_options_map_or_pid)
      - connection_options(map)

  """

  @type t :: %__MODULE__{
    structure: map,
    io:        map,
    runner:    module
  }
  @type result :: {:ok, map} | {:error, map}

  @max_processing_time :timer.minutes(1000)

  require Logger
  alias Helmsman.Processor.Cleanup
  alias Mapmaker.ProcessingTask

  defstruct [:structure, :io, :runner]

  @spec run(t, map, [(map -> map)]) :: Task.t
  def run(helmsman, postprocess) when is_list(postprocess), do: run(helmsman, %{}, postprocess)
  def run(helmsman, extra) when is_map(extra), do: run(helmsman, extra, [])
  def run(helmsman, extra \\ %{}, postprocess \\ []) do
    Task.async(__MODULE__, :do_run, [helmsman, extra, postprocess])
  end

  def do_run(helmsman, extra, postprocess) do
    result =
    Cleanup.with_cleaner fn(cleaner) ->
      extra = Map.put(extra, :cleaner, cleaner)
      {
        apply_middleware(helmsman.runner.run(helmsman.structure, helmsman.io.input, helmsman.io.output, extra), postprocess),
        helmsman
      }
    end
    log(:finish)
    result
  end

  @spec result(Task.t) :: result | :running
  def result(task) do
    Task.await(task, @max_processing_time)
  end

  @spec handle_result({result, t}) :: result
  def handle_result({{:ok, result}, helmsman}), do: {:ok, %{result: result}}
  def handle_result({{:error, %{error: reason}}, _helmsman}), do: {:error, reason}
  def handle_result({{:error, reason}, _helmsman}), do: {:error, reason}

  def read([structure: structure, io: io]) do
    {:ok, %__MODULE__{structure: structure, io: io, runner: Mapmaker}}
  end
  def read([json: json]) do
    with {:ok, structure, io} <- Mapmaker.decode(json),
    do: read([structure: structure, io: io])
  end
  def read([file: path]) do
    with {:ok, json} <- File.read(path), do: read([json: json])
  end

  def apply_middleware({:ok, result}, functions) do
    {:ok, Enum.reduce(functions, result, & &1.(&2))}
  end
  def apply_middleware({:error, _} = res, functions), do: res


  def log(:finish) do
    Logger.info("Finished processing")
  end
end
