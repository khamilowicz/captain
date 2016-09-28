defmodule Helmsman.Handler do
  @moduledoc """
  `Helmsman.Handler` uses configured `:handler` to execute `processor` with given `input`.

  By default `Helmsman.Handler.DBus` is used to communicate with processing machines.
  For details see `Helmsman.Handler.DBus` documentation.

  Processor handler can be configured with:

      config :helmsman, :handler,
        mod: MyApplication.CustomHandlder,
        connection: MyApplication.HandlerConnection

  `MyApplication.CustomHandlder` should implement `start_processor` function.
  For details see `Helmsman.Handler.start_processor/3`.

  `MyApplication.HandlerConnection` should be supervisor responsible for spawning connections with processor server.
  """

  @doc """
  Executes given `processor` with `input` and returns `{:ok, result}` or `{:error, reason}`.

  By default `Handler` uses `Helmsman.Handler.DBus` to send data to processing machine and return result.
  """
  defdelegate start_processor(processor, input, extra), to: Application.get_env(:helmsman, :handler)[:mod]
end
