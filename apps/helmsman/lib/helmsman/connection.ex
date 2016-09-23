defmodule Helmsman.Connection do
  require Logger
  use DBux.PeerConnection
  alias Helmsman.Connection.MessageParser
  alias Helmsman.Connection.Pool
  alias Helmsman.Utils

  @processing_timeout :timer.minutes(1) #TODO Change to actual
  @signal_processing_finished "OnProcessingFinished"
  @processing_path "/Launcher"
  @disconnect_after :timer.minutes(5)

  @type t :: %__MODULE__{
    processes: %{required(String.t) => pid},
    state: :up | :idle
  }
  defstruct [
    processes: %{},
    state: :idle
  ]

  @spec connect(%{address: String.t}) :: {:ok, pid} | {:error, any}
  def connect(%{address: _address} = params) do
    log(:connect, params)
    Pool.get_or_start_connection(params)
  end

  @spec disconnect(map | pid) :: :ok
  def disconnect(params_or_pid) do
    log(:disconnect, params_or_pid)
    Pool.disconnect(params_or_pid)
  end

  def send_async_message(connection, %{interface: _interface, path: _path, message: message, member: _member} = params) do
    log(:sending_message, connection, params)
    Utils.repeat(
                 fn -> DBux.PeerConnection.call(connection, {:send_async_message, message, params}) end,
                 fn(reason) -> log(:connection_error, connection, reason); Process.sleep(100) end)
  end

  @spec send_message(pid, map) ::{:ok, [any]} | {:error, [any]}
  def send_message(connection, %{interface: _interface, path: _path, message: message, member: _member} = params) do
    log(:sending_message, connection, params)
    Utils.repeat(
                 fn -> DBux.PeerConnection.call(connection, {:send_message, message, params}) end,
                 fn(reason) -> log(:connection_error, connection, reason); Process.sleep(100) end)
    |> wait_for_result(connection)
    |> log(connection)
  end
  def send_message(_connection, params) do
    {:error, ["Params should contain keys [interface, path, message, member], contains #{Map.keys(params)}"]}
  end

  ## Callbacks

  def start_link(args, options \\ []) do
    DBux.PeerConnection.start_link(__MODULE__, args, options)
  end

  def init(params) do
    initial_state = struct(__MODULE__, params)
    Logger.metadata([address: params[:address]])
    log(:init)
    {:ok, params[:address], [:anonymous], initial_state}
  end

  def handle_info(:disconnect_if_necessary, state) do
    if empty?(state) do
      disconnect(self)
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_call({:send_async_message, message, %{interface: _, path: _, member: _, identifier: identifier} = params}, {pid, _ref}, %{state: :up} = state) do
    log(:send_message, params)
    {:send, [
      {identifier, MessageParser.build_message(message, params)},
    ], add_process(state, identifier, pid)}
  end
  def handle_call({:send_message, message, %{interface: _, path: _, member: _, identifier: identifier} = params}, {pid, _ref}, %{state: :up} = state) do
    log(:send_message, params)
    {:send, [
      {identifier, MessageParser.build_message(message, params)},
      {:add_match, DBux.MessageTemplate.add_match(:signal, nil, "org.neutrino.audiomatic.Daemon.Launcher", nil, nil)},
    ], add_process(state, identifier, pid)}
  end
  def handle_call(_, _, %{state: :idle} = state), do: {:reply, {:error, "Server not connected, try in a second"}, state}

  def handle_down(state) do
    log(:down)
    {:backoff, 1000, state}
  end

  def handle_error(_serial, _sender, _reply_serial, error_name, body, identifier, state) do
    log(:error, %{error_name: error_name, body: body, identifier: identifier})
    return_error(state, identifier, body)
    {:noreply, state}
  end

  def handle_signal(_serial, _sender, @processing_path, @signal_processing_finished, _interface, body, state) do
    log(:signal, %{path: @processing_path, member: @signal_processing_finished, body: body})
    [_method, identifier, _, result] = body
    if handles_identifier?(state, identifier) do
      return_result(state, identifier, result)
      {:noreply, remove_process(state, identifier)}
    else
      {:noreply, state}
    end
  end
  def handle_signal(_serial, _sender, path, member, interface, body, state) do
    log(:signal, %{path: path, member: member, body: body})
    {:noreply, state}
  end

  def handle_up(state) do
    log(:up)
    {:noreply, %{state | state: :up}}
  end

  def terminate(reason, state) do
    disconnect(self)
    delete_temp_files(state)
    reason
  end

  ## Private
  #
  def delete_temp_files(state) do

  end

  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{processes: %{}}), do: true
  def empty?(%__MODULE__{processes: _}), do: false

  @spec handles_identifier?(t, String.t) :: boolean
  def handles_identifier?(%__MODULE__{processes: processes}, identifier) do
    Map.has_key?(processes, identifier)
  end

  @spec remove_process(t, String.t) :: t
  def remove_process(state, identifier) do
    new_state = update_in(state.processes, &Map.delete(&1, identifier))
    if empty?(new_state), do: Process.send_after(self, :disconnect_if_necessary, @disconnect_after)
    new_state
  end

  @spec add_process(t, String.t, pid) :: t
  def add_process(state, identifier, process) do
    put_in(state.processes[identifier], process)
  end

  def return_error(state, identifier, reason) do
    send state.processes[identifier], {:response, :error, reason}
  end

  def return_result(state, identifier, result) do
    send state.processes[identifier], {:response, :ok, result}
  end

  @spec wait_for_result(:ok | {:error, any}, pid) :: {:ok, [any]} | {:error, [any]}
  def wait_for_result({:error, reason} = err, connection) do
    log(:send_message_fail, connection, err)
    throw(:timeout)
  end
  def wait_for_result(:ok, connection) do
    log(:send_message_success, connection)
    receive do
      {:response, :ok, body} -> {:ok, List.wrap(body)}
      {:response, :error, body} -> {:error, List.wrap(body)}
    after
      @processing_timeout -> throw(:timeout)
    end
  end

  # Logging

  def log(:sending_message, connection, params) do
    Logger.debug("Attempting to call #{inspect connection} #{map_to_log(params)}")
  end
  def log(:send_message, params) do
    Logger.debug("Sending message #{map_to_log(params)}")
  end
  def log(:signal, params) do
    Logger.debug("Received signal: #{map_to_log(params)}")
  end
  def log(:error, params) do
    Logger.warn("Received error message: #{map_to_log params}")
  end
  def log(:connection_error, connection, reason) do
    Logger.warn("Attempt to connect to #{inspect connection}: #{inspect reason}")
  end
  def log(:init), do: Logger.debug("Initialized")
  def log(:up), do: Logger.debug("Connected")
  def log(:down), do: Logger.warn("Connection down")
  def log(:send_message_fail, connection, reason) do
    Logger.warn("Couldn't send message to #{inspect connection} : #{inspect reason}")
  end
  def log(:send_message_success, connection) do
    Logger.debug("Sent message to #{inspect connection}")
  end
  def log({:ok, result} = res, connection) do
    Logger.debug("Successful message return from #{inspect connection}: #{inspect result}")
    res
  end
  def log({:error, reason} = res, connection) do
    Logger.warn("Fail message return from #{inspect connection}: #{inspect reason}")
    res
  end
  def log(:connect, params), do: Logger.debug("Connecting #{map_to_log params}")
  def log(:disconnect, params), do: Logger.debug("Disconnecting #{map_to_log params}")

  def map_to_log(pid) when is_pid(pid), do: inspect(pid)
  def map_to_log(enum) when is_map(enum) do
    Enum.map_join(enum, " ", fn({k,v}) -> "#{k}=#{inspect(v)}" end)
  end

end
