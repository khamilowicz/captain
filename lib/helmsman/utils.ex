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
  iex> Helmsman.Utils.remap_keys(%{in1: "c", in2: "d", in3 => "f"}, %{in1: "a", in2: "b"})
  %{"a" => "c", "b" => "d"}
  """
  @spec remap_keys(map, map) :: map
  def remap_keys(map, key_mappings) do
    Enum.reduce key_mappings, %{}, fn
      {:outN, {new_key, n_key_mappings}}, acc ->
        new_value = Map.get(map, :outN, []) 
                    |> Enum.map(&remap_keys(&1, n_key_mappings))
        Map.put(acc, new_key, new_value)
      {common_key, new_key}, acc -> Map.put(acc, new_key, map[common_key])
    end
  end
end
