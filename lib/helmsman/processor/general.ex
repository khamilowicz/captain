defmodule Helmsman.Processor.General do
  alias Helmsman.{Processor, Processor.FileManager}

  def run(input, extra) do
    Task.async(fn ->
      input = generate_output_locations(extra[:output], input)

      case Processor.start_processor(extra[:processor], input, extra) do
        # input contains OUTPUT value, processor doesn't need result of operation
        #
        {:ok, _result} -> {:ok, input}
        {:error, reason} -> {:error, reason}
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
