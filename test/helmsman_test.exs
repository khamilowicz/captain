defmodule HelmsmanTest do
  use ExUnit.Case
  doctest Helmsman

  defmodule FailingDuration do
    def run(input, extra) do
      Task.async(fn -> {:error, "Oh snap!"} end)
    end
  end
  defmodule Duration do
    def run(input, extra) do
      Task.async(fn -> {:ok, %{out1: "duration result"}} end)
    end
  end

  describe "Given Mapper has processors set up" do
    setup [:configure_mapper]

    test "run/1 takes %Helmsman{} and starts processing", context do
      Application.put_env(Mapmaker, :processors, %{"duration" => HelmsmanTest.Duration})
      {:ok, helmsman} = Helmsman.read(file: "test/support/simple_structure.json")

      runner = Helmsman.run(helmsman)

      assert {:ok, %{result: %{"duration" => "duration result"}}} == Helmsman.result(runner)
    end

    test "run/1 takes %Helmsman{} and returns error when failing processor", context do
      Application.put_env(Mapmaker, :processors, %{"duration" => HelmsmanTest.FailingDuration})
      {:ok, helmsman} = Helmsman.read(file: "test/support/simple_structure.json")

      runner = Helmsman.run(helmsman)

      assert {:error, "Oh snap!"} == Helmsman.result(runner)
    end
  end

  defp configure_mapper(context) do
    Application.put_env(:helmsman, :processors, [
                        duration: [
                          connection: %{
                            hostname: "localhost",
                            port:     "12345"
                          }]])
      :ok
  end
end
