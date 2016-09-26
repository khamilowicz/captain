defmodule Mapmaker.ProcessingTasksSup do

  use Supervisor

  def start_processing(args) do
    Supervisor.start_child(Mapmaker.ProcessingTasksSup.ProcessingSup, args)
  end
  def start_task(fun) do
    Task.Supervisor.async_nolink(Mapmaker.ProcessingTasksSup.TaskSup, fun)
  end

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Mapmaker.ProcessingTasksSup.ProcessingSup, []),
      supervisor(Task.Supervisor, [[name: Mapmaker.ProcessingTasksSup.TaskSup]]),
    ]

    supervise(children, [strategy: :one_for_one])
  end

  defmodule ProcessingSup do
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
end
