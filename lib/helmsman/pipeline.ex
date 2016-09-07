defmodule Helmsman.Pipeline do

  alias Helmsman.{Spec, Pipeable, Runnable, Utils}

  @type status :: :prepared | :running | :done | :failed

  @type t :: %__MODULE__{
    specs: [Spec.t],
    status: status
  }

  @derive [Helmsman.Runnable]

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

  @doc """
  #TODO: reword this
  Given io_keys, returns specs that can use them
  """
  @spec for_inputs(t, [String.t]) :: t
  def for_inputs(pipeline, keys) do
    update_in pipeline.specs, &Enum.filter(&1, fn(spec) -> Pipeable.has_input_keys?(spec, keys) end)
  end

  @spec append_specs(t, [Spec.t]) :: t
  def append_specs(pipeline, specs) do
    %{pipeline | specs: pipeline.specs ++ specs}
  end

  @spec prepared_specs(t) :: [Spec.t]
  def prepared_specs(pipeline) do
    pipeline.specs |> Enum.filter(&Runnable.prepared?/1)
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

  @spec status(t) :: status
  def status(%{status: status}), do: status

  @spec remove_specs(t, [Spec.t]) :: t
  def remove_specs(pipeline, specs) do
    update_in pipeline.specs, &(&1 -- specs)
  end

  @spec run(t, map) :: {t, map}
  def run(pipeline, input) do
    case status(pipeline) do
      :failed -> {pipeline, input}
      :done -> {pipeline, input}
      other when other in [:prepared, :running] ->
        {new_pipeline, new_input} = do_run(pipeline, input)
        run(new_pipeline, new_input)
    end
  end

  def do_run(pipeline, input) do
    current_pipeline =
      for_inputs(pipeline, Map.keys(input))
      |> update_status

    if status(current_pipeline) in [:running, :prepared] do
      {new_specs, outputs} =
        current_pipeline
        |> prepared_specs
        |> Enum.map(&Runnable.run(&1, input))
        |> Utils.transpose_tuples


      result = Enum.reduce(outputs, input, &Map.merge/2)
      new_pipeline =
        pipeline
        |> remove_specs(current_pipeline |> prepared_specs)
        |> append_specs(new_specs)
        |> update_status

      {new_pipeline, result}
    else
      {current_pipeline, input}
    end
  end
end
