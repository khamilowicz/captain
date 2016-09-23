defmodule Mapmaker.Utils do

  @doc """
    iex> Mapmaker.Utils.input_joins(%{"in1" => "a", "in2" => "b"}, %{"b" => "c", "a" => "d", "h" => "f"})
    %{"in1" => "d", "in2" => "c"}

    iex> Mapmaker.Utils.input_joins(%{"inN" => %{"key" => "a", "mappings" => %{"in1" => "g", "in2" => "i"}}}, %{"b" => "c", "a" => [%{"g" => "hello", "i" => "hi"}], "h" => "f"})
    %{"inN" => [%{"in1" => "hello", "in2" => "hi"}]}
  """
  @spec input_joins(map, map) :: map
  def input_joins(spec_input, input) do
    Enum.reduce spec_input, %{}, fn
      {"inN", %{"key" => common_key, "mappings" => n_key_mappings}}, acc ->
        new_value = Map.get(input, common_key, []) |> Enum.map(&input_joins(n_key_mappings, &1))
        Map.put(acc, "inN", new_value)
      {key, val}, acc -> Map.put(acc, key, input[val])
    end
  end

  @doc """
  iex> Mapmaker.Utils.remap_keys(%{in1: "c", in2: "d", in3: "f"}, %{in1: "a", in2: "b"})
  %{"a" => "c", "b" => "d"}
  """
  @spec remap_keys(map, map) :: map
  def remap_keys(map, key_mappings) do
    Enum.reduce key_mappings, %{}, fn
      {"outN", %{"key" => new_key, "mappings" => n_key_mappings}}, acc ->
        new_value = Map.get(map, "outN", []) |> Enum.map(&remap_keys(&1, n_key_mappings))
        Map.put(acc, new_key, new_value)
      {common_key, new_key}, acc -> Map.put(acc, new_key, map[common_key])
    end
  end

  @doc """
    iex> Mapmaker.Utils.is_sublist?([1,2,3], [1,2])
    true
    iex> Mapmaker.Utils.is_sublist?([1,2,3], [1,2,4])
    false
  """
  @spec is_sublist?([], []) :: boolean
  def is_sublist?(list, sublist) do
    Enum.all?(sublist, &(&1 in list))
  end

  @doc """
  Changes list of tuples into tuple of lists

    iex> Mapmaker.Utils.transpose_tuples([{1, "a"}, {2, "b"}, {3, "c"}])
    {[1,2,3], ["a", "b", "c"]}
  """
  def transpose_tuples(tuples) when is_list(tuples) do
    Enum.reduce Enum.reverse(tuples), {[], []}, fn
      {f, s}, {firsts, seconds} -> {[f | firsts], [s | seconds]}
    end
  end
end
