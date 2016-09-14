defmodule Helmsman.Processors.Duration do

  @interface    "org.neutrino.DBus"
  @path         "/Neutrino/Processing/Processor"
  @member       "Start"
  # @member       "Finish"
  # @member       "Error"

  def run(input, extra) do
    Task.async(fn ->
      {:ok, connection} = establish_connection
      response = Helmsman.Connection.send_message(
                                                  connection, %{
                                                    interface: @interface,
                                                    path:      @path,
                                                    member:    @member,
                                                    message:   "ThisIsMyMessage"
                                                  })
        case response do
          {:ok, result} -> %{out1: result}
          {:error, reason} -> %{error: reason}
        end
    end)
  end

  def establish_connection do
    pid = Helmsman.Connection.start_link(options)
    Process.sleep(100)
    pid
  end

  def options do
    %{
      hostname:     "localhost",
      port:         "12345",
    }
  end
end
