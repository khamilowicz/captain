defmodule Helmsman.Connection.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Helmsman.Connection, [], restart: :transient)
    ]

    options = [
      strategy: :simple_one_for_one
    ]

    supervise(children, options)
  end

end
