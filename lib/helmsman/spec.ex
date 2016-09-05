defmodule Helmsman.Spec do
  @moduledoc """
  Converts raw map/json spec into Spec struct
  """

  alias Helmsman.Processors

  @type t :: %{
    processor: module,
    input: %{atom => String.t},
    output: %{atom => String.t},
  }

  @input_reg ~r{^in\d\d?$}
  @output_reg ~r{^out\d\d?$}

  defstruct [
    processor: nil,
    input: %{},
    output: %{}
  ]

  @spec to_spec(map) :: t
  def to_spec(raw_spec) when is_map(raw_spec) do
    %__MODULE__{
      processor: Processors.fetch!(raw_spec["processor"]),
      input: to_inputs(raw_spec["input"]),
      output: to_outputs(raw_spec["output"]),
    }
  end

  @spec to_inputs(map) :: map
  def to_inputs(inputs) do
    select_regex_keys(inputs, @input_reg)
  end
  @spec to_outputs(map) :: map
  def to_outputs(inputs) do
    select_regex_keys(inputs, @output_reg)
  end

  @doc """
    iex> Helmsman.Spec.select_regex_keys(%{"abc" => 1, "bcd" => 2, "cde" => 3}, ~r{bc})
    %{abc: 1, bcd: 2}
  """
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
end
