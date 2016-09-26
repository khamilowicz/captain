defmodule Mapmaker.ProcessingTask do

  @type t :: %__MODULE__{
    task: Task.t
  }

  defstruct [
    :task
  ]

  @spec run(fun) :: t
  def run(fun) do
    %__MODULE__{
      task: Task.async(fun)
    }
  end

  @spec run(module, fun, any) :: t
  def run(module, fun, args) do
    %__MODULE__{
      task: Task.async(module, fun, args)
    }
  end

  @spec result(t) :: :running | {:ok, any} | {:exit, any}
  def result(%__MODULE__{task: task}, timeout \\ 5000) do
    Task.yield(task, timeout) || :running
  end
end
