defmodule Helmsman.Processor.General do
  use Helmsman.Processor

  def run(input, extra) do
    Task.async(fn ->
      input = generate_output_locations(extra[:output], input)

      case start_processor(extra[:processor], input) do
        # input contains OUTPUT value, processor doesn't need result of operation
        #
        {:ok, _result} -> {:ok, input}
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  def generate_file_name(prefix \\ "") do
    prefix <> (:crypto.strong_rand_bytes(10) |> Base.url_encode64)
  end

  def generate_output_locations(output, input) do
    output
    |> Enum.map(fn({out_name, out_identifier}) -> {out_name, generate_file_name(out_identifier)} end)
    |> Enum.into(%{})
    |> Map.merge(input)
  end
end
