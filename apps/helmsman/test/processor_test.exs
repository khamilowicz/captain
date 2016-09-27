defmodule Helmsman.DBusTest do
  use ExUnit.Case, async: true

  import Helmsman.ProcessorHelpers

  setup [:setup_config]

  test "module implementing processor reads its configuration from file" do
    assert %{
      "connection" => %{
        "address" => "tcp:host=localhost,port=12345"},
      "message" => %{
        "interface" => "org.neutrino.DBus",
        "member" => "duration",
        "path" => "/Neutrino/Processing/Processor"}
    } = Helmsman.Handler.DBus.config("duration")
  end
end
