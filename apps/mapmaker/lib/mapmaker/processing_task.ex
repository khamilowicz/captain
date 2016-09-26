defmodule Mapmaker.ProcessingTask do
  use GenServer
  require Logger

  @type t :: %__MODULE__{
    task: Task.t
  }

  defstruct [
    :task
  ]

  @spec run(fun) :: t
  def run(fun) do
    {:ok, pid} = Supervisor.start_child(Mapmaker.ProcessingTaskSup, [fun])
    %__MODULE__{
      task: pid
    }
  end

  @spec run(module, fun, any) :: t
  def run(module, fun, args) do
    {:ok, pid} = Supervisor.start_child(Mapmaker.ProcessingTaskSup, [module, fun, args])
    %__MODULE__{
      task: pid
    }
  end

  @spec result(t) :: :running | {:ok, any} | {:exit, any}
  def result(%__MODULE__{task: pid}, timeout \\ 5000) when is_pid(pid) do
    GenServer.call(pid, :result, timeout)
  end

  def start_link(m, f, a) do
    GenServer.start_link(__MODULE__, [m,f,a])
  end
  def start_link(fun) do
    GenServer.start_link(__MODULE__, fun)
  end

  def init([module, fun, args]) do
    init(fn -> :erlang.apply(module, fun, args) end)
  end
  def init(fun) when is_function(fun) do
    task = Task.async_nolink(fun)
    Logger.info("Starting task #{inspect task.ref}")
    {:ok, %{ref: task.ref, task: task, result: :running}}
  end

  def handle_info({ref, result}, %{ref: ref} = state) do
    Logger.debug("Task #{inspect ref} finished with #{inspect result}")
    {:noreply, %{state | result: {:ok, result}}}
  end
  def handle_info({:DOWN, ref, _, _, :normal}, %{ref: ref} = state) do
    Logger.debug("Task #{inspect ref} stopped")
    {:noreply, state}
  end
  def handle_info({:DOWN, ref, _, _, reason}, %{ref: ref} = state) do
    Logger.warn("Task #{inspect ref} erred #{inspect reason}")
    {:noreply, %{state | result: {:error, reason}}}
  end
  def handle_info({:EXIT, _, :normal}, state), do: {:noreply, state}
  def handle_info(message, state) do
    Logger.warn("Unhandled #{inspect message}")
    {:noreply, state}
  end

  def handle_call(:result, _from, %{result: :running} = state) do
    {:reply, :running, state}
  end
  def handle_call(:result, _from, %{result: result} = state) do
    {:stop, :normal, result, state}
  end
end
