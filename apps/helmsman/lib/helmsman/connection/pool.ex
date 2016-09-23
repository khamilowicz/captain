defmodule Helmsman.Connection.Pool do

  def start_link(initial_value \\ %{}, opts) do
    Agent.start_link( fn -> initial_value end, opts)
  end

  @spec disconnect(map | pid) :: :ok
  def disconnect(connection) when is_pid(connection) do
    Agent.update(__MODULE__, fn(pool) ->
      {params, pool} = Map.pop(pool, connection)
      pool = Map.delete(pool, params)
      Supervisor.terminate_child(Helmsman.Connection.Supervisor, connection)
      pool
    end)
  end
  def disconnect(params) when is_map(params) do
    Agent.update(__MODULE__, fn(pool) ->
      {connection, pool} = Map.pop(pool, params)
      pool = Map.delete(pool, connection)
      Supervisor.terminate_child(Helmsman.Connection.Supervisor, connection)
      pool
    end)
  end

  @spec get_or_start_connection(map) :: {:ok, pid}
  def get_or_start_connection(params) do
    Agent.get_and_update(__MODULE__, fn(pool) ->
      case Map.get(pool, params) do
        nil ->
          {:ok, connection} = Supervisor.start_child(Helmsman.Connection.Supervisor, [params])
          {{:ok, connection}, Map.merge(pool, %{params => connection, connection => params})}
        connection -> {{:ok, connection}, pool}
      end
    end)
  end
end
