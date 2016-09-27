defmodule Helmsman.Postprocessors do

  defmodule ToJson do
    def run(input, _extra) do
      Poison.encode(input)
    end
  end

  defmodule Download do

    def run(file_url, extra) do
      filename = to_filename(file_url)
      with {:ok, file} <- File.open(filename, [:write]),
      {:ok, %{id: ref}} <- HTTPoison.get(file_url, %{}, stream_to: self),
      :ok <- receive_file(file, ref),
      :ok <- File.close(file) do
        {:ok, filename}
      else
        {:error, any} -> {:error, any}
        any -> {:error, any}
      end
    end

    def to_filename(file_url) do
      uri = URI.parse(file_url)
      "#{uri.host}-#{uri.path |> String.replace("/", "_")}"
    end

    def receive_file(file, ref) do
      receive do
        %HTTPoison.AsyncEnd{id: ^ref} -> :ok
        %HTTPoison.AsyncChunk{chunk: chunk, id: ^ref} ->
          :ok = IO.binwrite(file, chunk)
          receive_file(file, ref)
        _other -> receive_file(file, ref)
      end
    end
  end
end
