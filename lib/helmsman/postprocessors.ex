defmodule Helmsman.Postprocessors do

  defmodule ToJson do
    def run(input) do
      Poison.encode(input)
    end
  end

  defmodule Download do
    @server "http://192.168.1.20:9000"
    def run(filename) do
      File.open filename, [:write], fn(file) ->
        {:ok, %{id: ref}} = HTTPoison.get(@server <> "/#{filename}", %{}, stream_to: self)
        receive_file(file, ref)
      end
      {:ok, filename}
    end

    def receive_file(file, ref) do
      receive do
        %HTTPoison.AsyncChunk{chunk: chunk, id: ^ref} ->
          :ok = IO.binwrite(file, chunk)
          receive_file(file, ref)
        %HTTPoison.AsyncEnd{id: ^ref} -> :ok
        _other -> receive_file(file, ref)
      end
    end
  end
end
