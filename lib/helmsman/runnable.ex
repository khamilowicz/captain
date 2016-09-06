defprotocol Helmsman.Runnable do
  @dialyzer {:nowarn_function, __protocol__: 1}
  @fallback_to_any true

  @doc "Returns result as map with out* keys"
  def run(runnable, input)
end
