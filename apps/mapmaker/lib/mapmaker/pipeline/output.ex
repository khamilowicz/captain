defmodule Mapmaker.Pipeline.InOut do
  defstruct [:name, :process, :value]

  def process(io), do: io.process
  def name(io), do: io.name
  def value(io), do: io.value
end
