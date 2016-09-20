defmodule HelmsmanTest do
  use ExUnit.Case, async: true
  doctest Helmsman
  import Helmsman.ProcessorHelpers

  defmodule FailingDuration do
    def run(_input, _extra) do
      Task.async(fn -> {:error, "Oh snap!"} end)
    end
  end
  defmodule Duration do
    def run(_input, _extra) do
      Task.async(fn -> {:ok, %{"out1" => "duration result"}} end)
    end
  end

  describe "Given Mapper has processors set up" do
    setup [:setup_config]

    test "run/1 takes %Helmsman{} and starts processing" do
      Application.put_env(Mapmaker, :processors, %{"duration" => HelmsmanTest.Duration})
      {:ok, helmsman} = Helmsman.read(file: "test/support/simple_structure.json")

      runner = Helmsman.run(helmsman)

      assert {:ok, %{result: %{"duration" => "duration result"}}} == Helmsman.result(runner)
    end

    test "run/1 takes %Helmsman{} and returns error when failing processor" do
      Application.put_env(Mapmaker, :processors, %{"duration" => HelmsmanTest.FailingDuration})
      {:ok, helmsman} = Helmsman.read(file: "test/support/simple_structure.json")

      runner = Helmsman.run(helmsman)

      assert {:error, "Oh snap!"} == Helmsman.result(runner)
    end

    test "run/1 takes %Helmsman{} and uses General processor" do
      Application.put_env(Mapmaker, :processors, %{"any" => Helmsman.Processor.General})
      {:ok, helmsman} = Helmsman.read(file: "test/support/general_structure.json")

      runner = Helmsman.run(helmsman)

      assert {:ok, %{result: %{"special_processing" =>
         %Helmsman.TestConnection{
           connection_opts: %{address: "configured_address"},
           message_params: %{
             interface: "configured_interface",
             member: "configured_member",
             message: {"my_special_processor", _, %{"INPUT" => "/path/to/file"}},
             path: "configured_path"
           }}}}
      } = Helmsman.result(runner)
    end
  end
end
