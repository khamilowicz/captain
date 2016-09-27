defmodule Helmsman.Handler.DBus.Config do

  def open(path) do
    YamlElixir.read_from_file(path)
  end
end
