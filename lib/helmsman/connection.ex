defmodule Helmsman.Connection do
  require Logger
  use DBux.PeerConnection
  alias Helmsman.Connection.MessageParser
  alias Helmsman.Connection.Pool
  alias Helmsman.Utils

  @processing_timeout :timer.minutes(100)
  @signal_processing_finished "OnProcessingFinished"
  @processing_path "/Launcher"
  @disconnect_after :timer.seconds(10)

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
    Pool.get_or_start_connection(params)
  end

  @spec disconnect(map | pid) :: :ok
  def disconnect(params_or_pid) do
    Pool.disconnect(params_or_pid)
  end

  def start_link(args, options \\ []) do
    DBux.PeerConnection.start_link(__MODULE__, args, options)
  end

  def init(params) do
    initial_state = struct(__MODULE__, params)
    {:ok, params[:address], [:anonymous], initial_state}
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

  @spec wait_for_result(:ok | {:error, any}) :: {:ok, [any]} | {:error, [any]}
  def wait_for_result({:error, _} = err), do: err
  def wait_for_result(:ok) do
    receive do
      {:response, :ok, body} -> {:ok, List.wrap(body)}
      {:response, :error, body} -> {:error, List.wrap(body)}
    after
      @processing_timeout -> throw(:timeout)
    end
  end

  @spec send_message(pid, map) ::{:ok, [any]} | {:error, [any]}
  def send_message(connection, %{interface: _interface, path: _path, message: message, member: _member} = params) do
    Utils.repeat(
       fn -> DBux.PeerConnection.call(connection, {:send_message, message, params}) end,
       fn(_) -> Process.sleep(100) end)
    |> wait_for_result
  end
  def send_message(_connection, params) do
    {:error, ["Params should contain keys [interface, path, message, member], contains #{Map.keys(params)}"]}
  end

  def handle_info(:disconnect_if_necessary, state) do
    if empty?(state) do
      disconnect(self)
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end
  def handle_call({:send_message, message, %{interface: _, path: _, member: _, identifier: identifier} = params}, {pid, _ref}, %{state: :up} = state) do
    {:send, [
      {identifier, MessageParser.build_message(message, params)},
      {:add_match, DBux.MessageTemplate.add_match(:signal, nil, "org.neutrino.audiomatic.Daemon.Launcher", nil, nil)},
    ], add_process(state, identifier, pid)}
  end
  def handle_call(_, _, %{state: :idle} = state), do: {:reply, {:error, "Server not connected, try in a second"}, state}

  def handle_down(state) do
    Logger.warn("Down")
    {:backoff, 1000, state}
  end

  def handle_error(_serial, _sender, _reply_serial, _error_name, body, identifier, state) do
    IO.inspect("ERROR")
    IO.inspect(inspect identifier)
    IO.inspect(inspect body)
    return_error(state, identifier, body)
    {:noreply, state}
  end

  def handle_signal(_serial, _sender, @processing_path, @signal_processing_finished, _interface, body, state) do
    Logger.info("received signal finish #{inspect(self)}")
    [_method, identifier, _, result] = body
    if handles_identifier?(state, identifier) do
      return_result(state, identifier, result)
      {:noreply, remove_process(state, identifier)}
    else
      {:noreply, state}
    end
  end
  def handle_signal(_serial, _sender, path, member, interface, body, state) do
    IO.inspect("Signal")
    IO.inspect(inspect interface)
    IO.inspect(inspect body)
    IO.inspect(inspect member)
    IO.inspect(inspect path)
    {:noreply, state}
  end

  def handle_up(state) do
    Logger.info("Up")
    {:noreply, %{state | state: :up}}
  end

  def terminate(reason, _state) do
    disconnect(self)
    reason
  end
end
