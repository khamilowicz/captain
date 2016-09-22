defmodule Helmsman.TestConnection do

  defstruct [:connection_opts, :message_params]

  def connect(opts), do: Agent.start_link(fn -> %__MODULE__{connection_opts: opts} end)
  def disconnect(_opts), do: :ok

  def send_message(connection, params) do
    state = Agent.get(connection, & &1)
    {:ok, %{state | message_params: params}}
  end

end
