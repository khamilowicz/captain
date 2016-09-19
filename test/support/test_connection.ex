defmodule Helmsman.TestConnection do

  defstruct [:connection_opts, :message_params]

  def start_link(opts), do: Agent.start_link(fn -> %__MODULE__{connection_opts: opts} end)

  def send_message(connection, params) do
    state = Agent.get(connection, & &1)
    {:ok, %{state | message_params: params}}
  end

end
