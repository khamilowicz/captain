defmodule Helmsman.Handler.DBus.Cleanup do

  def start_link, do: Agent.start_link(fn -> [] end)

  def add_cleanup(cleaner, mod, fun, args) do
    Agent.update cleaner, &[{mod, fun, args} | &1]
  end

  def cleanup(cleaner) do
    clean_jobs = Agent.get(cleaner, & &1)
    Enum.map(clean_jobs, fn({m, f, a}) -> apply(m,f,a) end)
  end

  def with_cleaner(fun) do
    {:ok, cleaner} = start_link
    result = fun.(cleaner)
    cleanup(cleaner)
    result
  end
end
