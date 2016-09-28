defmodule Helmsman.Connection.Pool do

  use GenServer

  @spec disconnect(map | pid) :: :ok
  def disconnect(connection_or_params) do
    GenServer.call(__MODULE__, {:disconnect, connection_or_params})
  end

  def add_connection(pid, params) do
    GenServer.call(__MODULE__, {:add, pid, params})
  end

  @spec get_connection(map) :: {:ok, pid}
  def get_connection(params) do
    GenServer.call(__MODULE__, {:get, params})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  #TODO: Handle many connections with same params
  #
  def handle_call({:add, connection, params}, _from, pool) do
    case Map.get(pool, params) do
      nil ->
        Process.monitor(connection)
        {:reply, {:ok, connection}, add_process(pool, connection, params)}
      connection -> {:reply, {:ok, connection}, pool}
    end
  end

  def handle_call({:get, params}, _from, pool) do
    case Map.get(pool, params) do
      nil -> {:reply, :no_connection, pool}
      connection -> {:reply, {:ok, connection}, pool}
    end
  end

  def handle_call({:disconnect, connection}, _from, pool) do
    {:reply, :ok, remove_process(pool, connection)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, pool) do
    {:noreply, remove_process(pool, pid)}
  end

  # Private
  #
  def add_process(pool, pid, params) do
    Map.merge(pool, %{params => pid, pid => params})
  end

  def remove_process(pool, ar1) do
    {ar2, pool} = Map.pop(pool, ar1)
    Map.delete(pool, ar2)
  end
end
