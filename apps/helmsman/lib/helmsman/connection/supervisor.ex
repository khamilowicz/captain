defmodule Helmsman.Connection.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    connection_module = Application.get_env(:helmsman, :handler)[:connection]

    children = [
      worker(connection_module, [], restart: :transient)
    ]

    options = [
      strategy: :simple_one_for_one
    ]

    supervise(children, options)
  end

end
