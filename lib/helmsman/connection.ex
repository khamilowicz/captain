defmodule Helmsman.Connection do
  require Logger
  use DBux.PeerConnection

  @request_name_message_id __MODULE__
  @add_match_message_id    :add_match
  @identifier "somehting"
  @match "somehting"
  @request_name "somehting"

  defstruct hostname: nil, port: nil, processes: %{}, state: :idle

  def connect(%{hostname: _hostname, port: _port} = params) do
    Supervisor.start_child(Helmsman.Connection.Supervisor, [params])
  end

  def send_message(connection, %{interface: _interface, path: _path, message: message, member: _member} = params)
  when is_bitstring(message) do
    DBux.PeerConnection.call(connection, {:send_message, params})
    receive do
      {:response, body} -> {:ok, body}
    after
      1000 -> throw(:timeout)
    end
  end
  def send_message(connection, params) do
    {:exit, "Params should contain keys [interface, path, message, member], contains #{Map.keys(params)}"}
  end

  def handle_call({:send_message, %{interface: interface, path: path, message: message, member: member}}, {pid, ref}, %{state: :up} = state) do
    messages = [{ref,
        DBux.Message.build_method_call(
                                     path,
                                     interface,
                                     member,
                                     "s", [
                                       %DBux.Value{type: :string, value: message}
                                     ]
                                   )
                                  }]
    {:send, messages, put_in(state.processes[ref], pid)}
  end

  def start_link(args, options \\ []) do
    DBux.PeerConnection.start_link(__MODULE__, args, options)
  end

  def handle_down(state) do
    Logger.warn("Down")
    {:backoff, 1000, state}
  end

  def init(params) do
    initial_state = struct(__MODULE__, params)
    {:ok, "tcp:host=#{initial_state.hostname},port=#{initial_state.port}", [:anonymous], initial_state}
  end

  def handle_method_return(serial, sender, reply_serial, body, lol, state) do
    {:noreply, state}
  end
  def handle_error(serial, sender, reply_serial, error_name, body, identifier, state) do
    send state.processes[identifier], {:response, body}
    {:noreply, state}
  end

  def handle_signal(serial, sender, path, member, interface, body, state) do
    {:noreply, state}
  end

  def handle_up(state) do
    Logger.info("Up")
    {:noreply, %{state | state: :up}}
  end
end
