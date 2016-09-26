defmodule Mapmaker.ProcessingTaskSup do

  use Supervisor

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Mapmaker.ProcessingTask, [], [restart: :transient, max_seconds: 60])
    ]

    supervise(children, [strategy: :simple_one_for_one])
  end
end
