defmodule Helmsman.TestConnection do

  defstruct [:connection_opts, :message_params]

  def establish_connection(opts), do: Agent.start_link(fn -> %__MODULE__{connection_opts: opts} end)
  def disconnect(_opts), do: :ok

  def start_processor(_,input,_) do
    {:ok, input}
  end

  def start_link(opts) do
    Agent.start_link(fn -> opts end)
  end

  def send_message(connection, params) do
    state = Agent.get(connection, & &1)
    {:ok, %{state | message_params: params}}
  end

  def send_async_message(connection, params) do
    state = Agent.get(connection, & &1)
    {:ok, %{state | message_params: params}}
  end
end
