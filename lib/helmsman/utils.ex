defmodule Helmsman.Utils do

  @doc """
    iex> Helmsman.Utils.input_joins(%{in1: "a", in2: "b"}, %{"b" => "c", "a" => "d", "h" => "f"})
    %{in1: "d", in2: "c"}

    iex> Helmsman.Utils.input_joins(%{inN: {"a", %{in1: "g", in2: "i"}}}, %{"b" => "c", "a" => [%{"g" => "hello", "i" => "hi"}], "h" => "f"})
    %{inN: [%{in1: "hello", in2: "hi"}]}
  """
  @spec input_joins(map, map) :: map
  def input_joins(spec_input, input) do
    Enum.reduce spec_input, %{}, fn
      {:inN, {common_key, n_key_mappings}}, acc ->
        new_value = Map.get(input, common_key, [])
                    |> Enum.map(&input_joins(n_key_mappings, &1))
        Map.put(acc, :inN, new_value)
      {key, val}, acc -> Map.put(acc, key, input[val])
    end
  end

  @doc """
  iex> Helmsman.Utils.remap_keys(%{in1: "c", in2: "d", in3: "f"}, %{in1: "a", in2: "b"})
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

  @doc """
  iex> Helmsman.Utils.select_regex_keys(%{"abc" => 1, "bcd" => 2, "cde" => 3}, ~r{bc})
  %{abc: 1, bcd: 2}
  """
  def select_regex_keys(nil, _regex), do: %{}
  def select_regex_keys(inputs, regex) when is_map(inputs) do
    Enum.reduce inputs, %{}, fn
      {key, val}, acc ->
        if key =~ regex do
          Map.put(acc, String.to_atom(key), val)
        else
          acc
        end
    end
  end

  @doc """
    iex> Helmsman.Utils.is_sublist?([1,2,3], [1,2])
    true
    iex> Helmsman.Utils.is_sublist?([1,2,3], [1,2,4])
    false
  """
  @spec is_sublist?([], []) :: boolean
  def is_sublist?(list, sublist) do
    Enum.all?(sublist, &(&1 in list))
  end

  @doc """
  Changes list of tuples into tuple of lists

    iex> Helmsman.Utils.transpose_tuples([{1, "a"}, {2, "b"}, {3, "c"}])
    {[1,2,3], ["a", "b", "c"]}
  """
  def transpose_tuples(tuples) when is_list(tuples) do
    Enum.reduce Enum.reverse(tuples), {[], []}, fn
      {f, s}, {firsts, seconds} -> {[f | firsts], [s | seconds]}
    end
  end
end
