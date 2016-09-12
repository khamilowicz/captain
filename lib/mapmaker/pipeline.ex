defmodule Mapmaker.Pipeline do

  alias Mapmaker.{Spec, Pipeable, Runnable, Utils}

  @type status :: :prepared | :running | :done | :failed

  @type t :: %__MODULE__{
    specs: [Spec.t],
    status: status
  }

  @derive [Mapmaker.Runnable]

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

  @spec prepared_and_running_specs(t) :: [Spec.t]
  def prepared_and_running_specs(pipeline) do
    pipeline.specs |> Enum.filter(&(Runnable.prepared?(&1) || Runnable.running?(&1)))
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

  @spec run(t, map, map) :: {t, map}
  def run(pipeline, input, extra) do
    case status(pipeline) do
      :failed -> {pipeline, input}
      :done -> {pipeline, input}
      other when other in [:prepared, :running] ->
        {new_pipeline, new_input} = do_run(pipeline, input, extra)
        run(new_pipeline, new_input, extra)
    end
  end

  def run_specs(selected_specs, input, extra) do
    selected_specs
    |> Enum.map(&Runnable.run(&1, input, extra))
    |> Utils.transpose_tuples
  end

  def update(pipeline, options) do
    new_specs = Keyword.get(options, :append, [])
    remove_specs = Keyword.get(options, :remove, [])

    pipeline
    |> remove_specs(remove_specs)
    |> append_specs(new_specs)
    |> update_status
  end

  def do_run(pipeline, input, extra) do
    current_pipeline =
      for_inputs(pipeline, Map.keys(input))
      |> update_status

    if status(current_pipeline) in [:running, :prepared] do
      selected_specs = prepared_and_running_specs(current_pipeline)

      {new_specs, outputs} = run_specs(selected_specs, input, extra)

      result = Enum.reduce(outputs, input, &Map.merge/2)
      new_pipeline = update(pipeline, append: new_specs, remove: selected_specs)

      {new_pipeline, result}
    else
      {current_pipeline, input}
    end
  end
end
