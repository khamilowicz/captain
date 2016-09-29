defmodule Helmsman.Connection.Pool do

  use GenServer

  @doc """
  Removes connection from pool. Accepts either pid of connection params. Returns `:ok`
  """
  @spec disconnect(map | pid) :: :ok
  def disconnect(connection_or_params)
  when is_pid(connection_or_params) or is_map(connection_or_params) do
    :ok = GenServer.call(__MODULE__, {:disconnect, connection_or_params})
  end

  @doc """
  Adds connection to pool. Returns `{:ok, pid]`
  """
  @spec add_connection(pid, map) :: {:ok, pid}
  def add_connection(pid, params)
  when is_pid(pid) and is_map(params) do
    case GenServer.call(__MODULE__, {:add, pid, params}) do
      {:ok, pid} when is_pid(pid) -> {:ok, pid}
    end
  end

  @doc """
  Returns `{:ok, pid}` or `:no_connection`
  """
  @spec get_connection(map) :: {:ok, pid} | :no_connection
  def get_connection(params) when is_map(params) do
    case GenServer.call(__MODULE__, {:get, params}) do
      {:ok, pid} = res when is_pid(pid) -> res
      :no_connection = res -> res
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  #TODO: Handle many connections with same params
  #
  @doc false
  def handle_call({:add, connection, params}, _from, pool) do
    case Map.get(pool, params) do
      nil ->
        Process.monitor(connection)
        {:reply, {:ok, connection}, add_process(pool, connection, params)}
        connection -> {:reply, {:ok, connection}, pool}
    end
  end

  @doc false
  def handle_call({:get, params}, _from, pool) do
    case Map.get(pool, params) do
      nil -> {:reply, :no_connection, pool}
      connection -> {:reply, {:ok, connection}, pool}
    end
  end

  @doc false
  def handle_call({:disconnect, connection}, _from, pool) do
    {:reply, :ok, remove_process(pool, connection)}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, pid, _reason}, pool) do
    {:noreply, remove_process(pool, pid)}
  end

  # Private
  #
  @spec add_process(map, pid, map) :: map
  def add_process(pool, pid, params)
  when is_map(pool) and is_pid(pid) and is_map(params) do
    Map.merge(pool, %{params => pid, pid => params})
  end

  @spec remove_process(map, any) :: map
  def remove_process(pool, ar1) when is_map(pool) do
    {ar2, pool} = Map.pop(pool, ar1)
    Map.delete(pool, ar2)
  end
end
