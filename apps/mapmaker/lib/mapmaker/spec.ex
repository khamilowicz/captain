defmodule Mapmaker.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct

  Examples

  iex> spec = %Mapmaker.Spec{}
  iex> spec = Mapmaker.Spec.put_processor(spec, MyProcessor)
  iex> Mapmaker.Spec.get_processor(spec)
  MyProcessor
  iex> spec = Mapmaker.Pipeable.put_input(spec, :in1, "a")
  iex> spec = Mapmaker.Pipeable.put_output(spec, :out1, "b")
  iex> Mapmaker.Pipeable.get_input(spec, :in1)
  "a"
  iex> Mapmaker.Pipeable.get_output(spec, :out1)
  "b"
  """

  alias Mapmaker.{Utils, Runnable, ProcessingTask}

  @type status :: :prepared | :failed | :done | :running

  @type t :: %{
    processor: module | {module, String.t},
    required: boolean,
    status: status,
    retries: non_neg_integer,
    state: nil | pid,
    input: %{atom => String.t},
    output: %{atom => String.t},
  }

  @task_blocking_time 5000
  @max_retries Map.get(Application.get_env(:mapmaker, :specs), :max_retries, 5)

  @derive [Mapmaker.Pipeable, Mapmaker.Runnable]

  defstruct [
    processor: NullProcessor,
    required: false,
    retries: 0,
    state: nil,
    status: :prepared,
    input: %{},
    output: %{}
  ]

  @spec to_spec(map, module) :: t | {:error, String.t}
  def to_spec(raw_spec, processors) when is_map(raw_spec) do
    case processors[raw_spec["processor"]] || processors["any"] do
      nil -> {:error, "Invalid processor #{raw_spec["processor"]}"}
      processor ->
        %__MODULE__{
          processor: {processor, raw_spec["processor"]},
          required: Map.get(raw_spec, "required", false),
          input: raw_spec["input"],
          output: raw_spec["output"],
        }
    end
  end

  @spec put_processor(t, module) :: t
  def put_processor(spec, module) do
    %{spec | processor: module}
  end

  @spec get_processor(t) :: module
  def get_processor(%{processor: processor}), do: processor

  @spec put_state(t, pid) :: t
  def put_state(spec, state), do: %{spec | state: state}

  @spec handle_processor_output(ProcessingTask.t | {:ok, map} | {:error, any}) :: {:ok, map} | no_return
  def handle_processor_output(%ProcessingTask{} = task) do
    case ProcessingTask.result(task, @task_blocking_time) do
      :running -> {:running, task}
      {:error, reason} -> throw(reason)
      {:ok, result} -> handle_processor_output(result)
    end
  end
  def handle_processor_output({:ok, result}), do: {:ok, result}
  def handle_processor_output({:error, reason}), do: throw(reason)

  def handle_computation_status({:ok, result}, spec) do
    {Runnable.done(spec), Utils.remap_keys(result, spec.output)}
  end
  def handle_computation_status({:running, state}, spec) do
    new_spec = spec |> put_state(state) |> Runnable.running
    {new_spec, %{}}
  end

  def run_processor({processor, ident}, input, extra),
    do: run_processor(processor, input, Map.put(extra, :processor, ident))
  def run_processor(processor, input, extra), do: processor.run(input, extra)

  def run(spec, input, extra) do
    try do
      extra = Map.put(extra, :output, spec.output)
      do_run(spec, Utils.input_joins(spec.input, input), extra)
    catch
      any -> {retry(spec, any), %{error: any}}
    end
  end

  def retry(%{retries: retries} = spec, _error) when retries < @max_retries,
    do: %{spec | retries: retries + 1, state: nil}
  def retry(%{retries: retries} = spec, error) when retries >= @max_retries,
    do: Runnable.fail(%{spec | state: error})

  def do_run(%{status: :running, state: state} = spec, _input, _extra) when not is_nil(state) do
    state |> handle_processor_output |> handle_computation_status(spec)
  end
  def do_run(spec, input, extra) do
    spec
    |> get_processor
    |> run_processor(input, extra)
    |> handle_processor_output
    |> handle_computation_status(spec)
  end
end
