defmodule Helmsman.Pipeline do

  alias Helmsman.{Spec, Pipeable, Runnable}

  @type status :: :prepared | :running | :done | :failed

  @type t :: %__MODULE__{
    specs: [Spec.t],
    status: status
  }

  defstruct [
    specs: [],
    status: :prepared
  ]


  @spec to_pipeline([Spec.t]) :: t
  def to_pipeline(specs) when is_list(specs) do
    %__MODULE__{specs: specs}
  end

  @spec for_input(t, String.t) :: [Spec.t]
  def for_input(pipeline, key) do
    Enum.filter(pipeline.specs, &Pipeable.has_input_key?(&1, key))
  end

  @spec append_specs(t, [Spec.t]) :: t
  def append_specs(pipeline, specs) do
    %{pipeline | specs: pipeline.specs ++ specs}
  end

  @spec update_status(t) :: t
  def update_status(pipeline) do
    cond do
      Enum.any?(pipeline.specs, &(Runnable.failed?(&1) && Runnable.required?(&1))) ->
        %{pipeline | status: :failed}
      Enum.all?(pipeline.specs, &(Runnable.failed?(&1) || Runnable.done?(&1))) ->
        %{pipeline | status: :done}
      true ->
        %{pipeline | status: :running}
    end
  end

  @spec remove(t, [Spec.t]) :: t
  def remove(pipeline, specs) do
    update_in pipeline.specs, &(&1 -- specs)
  end

  @spec empty?(t) :: boolean
  def empty?(%{specs: []}), do: true
  def empty?(_pipeline), do: false

  @spec status(t) :: status
  def status(%{status: status}), do: status

  @spec remove_specs(t, [Spec.t]) :: t
  def remove_specs(pipeline, specs) do
    update_in pipeline.specs, &(&1 -- specs)
  end

  @doc """
  #TODO: reword this
  Given io_keys, returns specs that can use them
  """
  @spec for_inputs(t, [String.t]) :: t
  def for_inputs(pipeline, keys) do
    update_in pipeline.specs, &Enum.filter(&1, fn(spec) -> Pipeable.has_input_keys?(spec, keys) end)
  end

end

defimpl Helmsman.Runnable, for: Helmsman.Pipeline do

  alias Helmsman.{Runnable, Pipeline, Utils, Spec}

  def failed?(pipeline), do: pipeline.status == :failed
  def done?(pipeline), do: pipeline.status == :done
  def required?(pipeline), do: pipeline.required

  def fail(pipeline) do
    %{pipeline | status: :failed}
  end

  def done(pipeline) do
    %{pipeline | status: :done}
  end

  def run(pipeline, input) do

    current_pipeline =
      Pipeline.for_inputs(pipeline, Map.keys(input))
      |> Pipeline.update_status

      if Pipeline.status(current_pipeline) in [:running, :prepared] do
        #TODO: Use new specs and pipeline to create new pipe
        {new_specs, outputs} =
          current_pipeline.specs
          |> Spec.prepared
          |> Enum.map(&Runnable.run(&1, input))
          |> Utils.transpose_tuples


        result = Enum.reduce(outputs, input, &Map.merge/2)
        new_pipeline = pipeline
                        |> Pipeline.remove_specs(current_pipeline.specs |> Spec.prepared)
                        |> Pipeline.append_specs(new_specs)
                        |> Pipeline.update_status

        {new_pipeline, result}
      else
        {current_pipeline, input}
      end
  end
end
