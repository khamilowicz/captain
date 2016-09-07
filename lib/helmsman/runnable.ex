defprotocol Helmsman.Runnable do
  @dialyzer {:nowarn_function, __protocol__: 1}

  @doc "Returns new runnable with result as map with out* keys"
  @spec run(Helmsman.Runnable.t, map) :: {Helmsman.Runnable.t, map}
  def run(runnable, input)

  @doc "Changes status of runnable to :failed"
  def fail(runnable)
  @doc "Changes status of runnable to :done"
  def done(runnable)

  def done?(runnable)
  def failed?(runnable)
  def required?(runnable)
  def prepared?(runnable)
end

defimpl Helmsman.Runnable, for: Any do
  def prepared?(runnable), do: runnable.status == :prepared
  def failed?(runnable), do:   runnable.status == :failed
  def done?(runnable), do:     runnable.status == :done
  def required?(runnable), do: runnable.required

  def fail(runnable), do: %{runnable | status: :failed}
  def done(runnable), do: %{runnable | status: :done}

  def run(runnable, input) do
    runnable.__struct__.run(runnable, input)
  end
end
