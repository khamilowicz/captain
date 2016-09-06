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

  @doc """
  #TODO: reword this
  Given io_keys, returns specs that can use them
  """
  @spec for_inputs(t, [String.t]) :: [Spec.t]
  def for_inputs(pipeline, keys) do
    Enum.filter(pipeline.specs, &is_sublist?(keys, Spec.input_keys(&1)))
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
