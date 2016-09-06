defmodule Helmsman.Utils do


  @doc """
  iex> Helmsman.Utils.syllogism_of_maps(%{in1: "a", in2: "b"}, %{"b" => "c", "a" => "d", "h" => "f"})
  %{in1: "d", in2: "c"}
  """
  @spec syllogism_of_maps(map, map) :: map
  def syllogism_of_maps(spec_input, input) do
    Enum.reduce spec_input, %{}, fn
      {key, val}, acc -> Map.put(acc, key, input[val])
    end
  end

  @doc """
    iex> Helmsman.Utils.join_by_keys(%{in1: "c", in2: "d", in3 => "f"}, %{in1: "a", in2: "b"})
    %{"a" => "c", "b" => "d"}
  """
  @spec remap_keys(map, map) :: map
  def remap_keys(map, key_mappings) do
    Enum.reduce key_mappings, %{}, fn
      {common_key, new_key}, acc -> Map.put(acc, new_key, map[common_key])
    end
  end

end
