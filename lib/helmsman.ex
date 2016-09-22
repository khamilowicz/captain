defmodule Helmsman do

  @type t :: %__MODULE__{
    structure: map,
    io:        map,
    runner:    module
  }
  @type result :: {:ok, map} | {:error, map}

  defstruct [:structure, :io, :runner]

  @spec run(t, map) :: Task.t
  def run(helmsman, extra \\ %{}) do
    Task.async(fn ->
      {helmsman.runner.run(helmsman.structure, helmsman.io.input, helmsman.io.output, extra), helmsman}
    end)
  end

  @spec result(Task.t) :: result | :running
  def result(task) do
    case Task.yield(task) do
      nil -> :running
      {:exit, reason} -> throw(reason)
      {:ok, result} -> handle_result(result)
    end
  end

  @spec handle_result({result, t}) :: result
  def handle_result({{:ok, result}, helmsman}) do
    #TODO: Add postprocessing to output
    {:ok, %{result: Map.take(result, Map.keys(helmsman.io.output))}}
  end
  def handle_result({{:error, %{error: reason}}, _helmsman}), do: {:error, reason}
  def handle_result({{:error, reason}, _helmsman}), do: {:error, reason}

  def read([file: path]) do
    with {:ok, json} <- File.read(path),
         {:ok, structure, io} <- Mapmaker.decode(json)
    do
      {:ok, %__MODULE__{structure: structure, io: io, runner: Mapmaker}}
    else
      {:error, _reason} = err -> err
    end
  end
end
