defmodule Helmsman.Processor.General do
  use Helmsman.Processor

  def run(input, extra) do
    Task.async(fn ->
      case send_message("ThisIsMyStandardMessage", extra[:processor]) do
        {:ok, result} -> {:ok, %{out1: result}}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

end
