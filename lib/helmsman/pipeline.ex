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
end
