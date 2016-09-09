defmodule Helmsman.Processors.Duration do


  def run(input, extra) do
    Helmsman.Connection.send_message(extra.connection, %{message: "Hello"})
    %{out1: "lol"}
  end

end
