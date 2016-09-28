defmodule Helmsman.Postprocessors do
  @moduledoc """
  Postprocessors are transducers changing values passed to it. They are used as `postproc` and `preproc` methods in `Mapmaker.Structure`.

  Postprocessors should implement method `run(value, extra)` where `value` is either input value of result of executing `Mapmaker.Structure`.
  """

  defmodule ToJson do
    @moduledoc """
    Postprocessor converting any value to JSON.

         Helmsman.Postprocessor.ToJson.run(%{hello: "hi"}, %{})
         {:ok, "{\"hello\": \"hi\"}"}
    """

    def run(input, _extra) do
      Poison.encode(input)
    end
  end

  defmodule Fetch do
    @moduledoc """
    Preprocessor downloading given url on processor machine.

         Helmsman.Postprocessor.Fetch.run("http://fileurl.com/file.mp3, %{})
         {:ok, "random filename on processing machine"}
    """
    def run(file_url, extra) do
      options =
      Helmsman.Handler.DBus.config("format") |> 
      Helmsman.Handler.DBus.connection_options

      [file_path] = Helmsman.Handler.DBus.fetch(options, file_url)

      {:ok, file_path}
    end
  end

  defmodule Download do
    @moduledoc """
    Preprocessor downloading given url on client machine..

         Helmsman.Postprocessor.Download.run("http://fileurl.com/file.mp3, %{})
         {:ok, "random filename on client machine"}
    """

    def run(file_url, extra) do
      IO.inspect(extra)
      filename = case Map.get(extra, "ext") do
        nil -> Map.get(extra, "filename", to_filename(file_url))
        ext -> Map.get(extra, "filename", to_filename(file_url)) <> "." <> ext
      end

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
