defmodule Helmsman.ProcessorTest do
  use ExUnit.Case, async: true

  import Helmsman.ProcessorHelpers

  setup [:setup_config]

  test "module implementing processor reads its configuration from file" do
    assert %{
      "connection" => %{
        "address" => "tcp:host=localhost,port=12345"
      }
    } = Helmsman.Processor.Duration.config
  end
end
