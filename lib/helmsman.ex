defmodule Helmsman do

  defstruct [:structure, :io, :runner]

  def run(helmsman, extra \\ %{}) do
    Task.async(fn ->
      {helmsman.runner.run(helmsman.structure, helmsman.io.input, helmsman.io.output, extra), helmsman}
    end)
  end

  def result(pid) do
    case Task.yield(pid) do
      {:error, reason} -> throw(reason)
      {:ok, {{:ok, result}, helmsman}} ->
        #TODO: Add postprocessing to output
        {:ok, %{result: Map.take(result, Map.keys(helmsman.io.output))}}
    end
  end

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
