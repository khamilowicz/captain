defmodule Helmsman.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false
    children = [
    ]

    options = [strategy: :one_for_one]
    supervise(children, options)
  end
end
