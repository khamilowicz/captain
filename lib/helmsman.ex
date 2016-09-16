defmodule Helmsman do

  defstruct [:structure, :io, :runner]

  def run(helmsman, extra \\ %{}) do
    Task.async(fn ->
      {helmsman.runner.run(helmsman.structure, helmsman.io.input, helmsman.io.output, extra), helmsman}
    end)
  end

  def result(pid) do
    case Task.yield(pid) do
      nil -> :running
      {:error, reason} -> throw(reason)
      {:ok, result} -> handle_result(result)
    end
  end

  @spec handle_result({{:ok, map} | {:error, map}, map}) :: {:ok, map} | {:error, map}
  def handle_result({{:ok, result}, helmsman}) do
    #TODO: Add postprocessing to output
    {:ok, %{result: Map.take(result, Map.keys(helmsman.io.output))}}
  end
  def handle_result({{:error, %{error: reason}}, helmsman}), do: {:error, reason}
  def handle_result({{:error, reason}, helmsman}), do: {:error, reason}

  def read([file: path]) do
    with {:ok, json} <- File.read(path),
         {:ok, structure, io} <- Mapmaker.decode(json)
    do
      {:ok, %__MODULE__{structure: structure, io: io, runner: Mapmaker}}
    else
      {:error, reason} = err -> err
      other -> {:error, other}
    end
  end
end
