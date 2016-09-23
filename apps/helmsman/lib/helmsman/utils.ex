defmodule Helmsman.Utils do

  @doc """
  iex> Helmsman.Utils.traverse([{"a", 1}, {"b", 2}, {"c", 3}])
  {["a", "b", "c"], [1, 2, 3]}
  """
  def traverse(list), do: do_traverse(list, {[], []})
  def do_traverse([], {facc, sacc}), do: {Enum.reverse(facc), Enum.reverse(sacc)}
  def do_traverse([{f, s} | rest], {facc, sacc}), do: do_traverse(rest, {[f | facc], [s | sacc]})

  def repeat(fun, on_error \\ &(&1), retries \\ 10)
  def repeat(fun, _on_error, retries) when retries <= 0, do: fun.()
  def repeat(fun, on_error, retries) do
    with {:error, reason} <- fun.() do
      on_error.(reason)
      repeat(fun, on_error, retries - 1)
    end
  end
end
