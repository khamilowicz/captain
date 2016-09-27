defmodule Helmsman.Processor.General do
  alias Helmsman.Handler.{DBus, DBus.FileManager}
  require Logger

  def run(input, extra) do
    Mapmaker.ProcessingTask.run(fn ->
      input = generate_output_locations(extra[:output], input)

      case DBus.start_processor(extra[:processor], input, extra) do
        # input contains OUTPUT value, processor doesn't need result of operation
        #
        {:error, reason} -> {:error, reason}
        {:ok, result} -> {:ok, result} |> IO.inspect
      end
    end)
  end

  def generate_output_locations(output, input) do
    output
    |> Enum.map(fn({out_name, out_identifier}) -> {out_name, FileManager.generate_file_name(out_identifier)} end)
    |> Enum.into(%{})
    |> Map.merge(input)
  end
end
