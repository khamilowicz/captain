defmodule Helmsman.Processor.Duration do

  use Helmsman.Processor, name: "duration"

  def run(input, extra) do
    Task.async(fn ->
      case send_message("ThisIsMyMessage") do
        {:ok, result} -> {:ok, %{out1: result}}
        {:error, reason} -> {:error, reason}
      end
    end)
  end
end
