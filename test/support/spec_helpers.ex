defmodule Helmsman.SpecHelpers do

  def one_to_one_raw_spec(context) do
    raw_spec = %{
      "processor" => "one.to.one",
      "input" => %{"in1" => "a"},
      "output" => %{"out1" => "b"},
    }
    {:ok, Map.put(context, :one_to_one_spec, raw_spec)}
  end

end
