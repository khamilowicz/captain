defprotocol Helmsman.Runnable do

  @doc "Returns result as map with out* keys"
  def run(runnable, input)
end
