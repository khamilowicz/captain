defmodule Helmsman.Processor.FileManager do

  @identifier "hpFMf"

  def generate_file_name(prefix \\ "") do
    prefix <> (:crypto.strong_rand_bytes(10) |> Base.url_encode64) <> @identifier
  end

  def filename?(name), do: String.ends_with?(name, @identifier)
end
