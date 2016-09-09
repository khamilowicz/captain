defmodule HelmsmanTest do
  use ExUnit.Case
  doctest Helmsman

  describe "Given Mapper has processors set up" do
    setup [:configure_mapper]

    @tag :skip
    test "run/1 takes %Helmsman{} and start processing" do
      {:ok, helmsman} = Helmsman.read(file: "test/support/simple_structure.json")

      {:ok, pid} = Helmsman.run(helmsman)

      assert %{result: []} == Helmsman.result(pid)
    end
  end

  defp configure_mapper(context) do
    Application.put_env(Mapmaker, :processors, %{"duration" => Helmsman.Processors.Duration})
    :ok
  end
end
