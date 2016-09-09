defmodule Helmsman.Connection do
  require Logger
  use DBux.PeerConnection

  @request_name_message_id __MODULE__
  @add_match_message_id    :add_match

  def run(mod, fun, args) do
    apply(mod, fun, args)
  end

  def result(connection) do
  end

  def send_message(connection, message) do
    DBux.PeerConnection.send_message(connection, message)
  end

  def start_link(args, options \\ []) do
    DBux.PeerConnection.start_link(__MODULE__, args, options)
  end

  def init(initial_state) do
    hostname = initial_state[:hostname]

    {:ok, "tcp:host=" <> hostname <> ",port=8888", [:anonymous], initial_state}
  end

  def handle_up(state) do
    Logger.info("Up")
    {:send, [
      DBux.Message.build_signal("/", state.identifier, "Connected", []),
      {@add_match_message_id,    DBux.MessageTemplate.add_match(:signal, nil, state.match)},
      {@request_name_message_id, DBux.MessageTemplate.request_name(state.request_name, 0x4)}
    ], state}
  end

end
