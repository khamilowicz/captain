defprotocol Helmsman.Runnable do
  @dialyzer {:nowarn_function, __protocol__: 1}

  @doc "Returns new runnable with result as map with out* keys"
  @spec run(Helmsman.Runnable.t, map) :: {Helmsman.Runnable.t, map}
  def run(runnable, input)
end
