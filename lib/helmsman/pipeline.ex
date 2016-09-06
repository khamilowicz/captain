defmodule Helmsman.Pipeline do

  alias Helmsman.Spec

  @type t :: %__MODULE__{
    specs: [Spec.t]
  }

  defstruct [
    specs: []
  ]


  @spec to_pipeline([Spec.t]) :: t
  def to_pipeline(specs) when is_list(specs) do
    %__MODULE__{specs: specs}
  end

  @spec for_input(t, String.t) :: [Spec.t]
  def for_input(pipeline, key) do
    Enum.filter(pipeline.specs, &(key in Spec.input_keys(&1)))
  end

  @spec remove(t, [Spec.t]) :: t
  def remove(pipeline, specs) do
    update_in pipeline.specs, &(&1 -- specs)
  end

  @spec empty?(t) :: boolean
  def empty?(%{specs: []}), do: true
  def empty?(_pipeline), do: false

  @spec subtract(t, t) :: t
  def subtract(pipeline1, pipeline2) do
    update_in pipeline1.specs, &(&1 -- pipeline2.specs)
  end

  @doc """
  #TODO: reword this
  Given io_keys, returns specs that can use them
  """
  @spec for_inputs(t, [String.t]) :: t
  def for_inputs(pipeline, keys) do
    update_in pipeline.specs, &Enum.filter(&1, fn(spec) -> is_sublist?(keys, Spec.input_keys(spec)) end)
  end

  @doc """
    iex> Helmsman.Pipeline.is_sublist?([1,2,3], [1,2])
    true
    iex> Helmsman.Pipeline.is_sublist?([1,2,3], [1,2,4])
    false
  """
  @spec is_sublist?([], []) :: boolean
  def is_sublist?(list, sublist) do
    Enum.all?(sublist, &(&1 in list))
  end
end

defimpl Helmsman.Runnable, for: Helmsman.Pipeline do

  alias Helmsman.Runnable

  def run(pipeline, input) do
    pipeline.specs
    |> Enum.map(&Runnable.run(&1, input))
    |> Enum.reduce(input, &Map.merge/2)
  end
end
