defmodule Helmsman.Processors do

  defmodule Undefined do
    defexception [:message]
  end

  defp processors, do: Application.get_env(Helmsman, :processors, [])

  @spec fetch!(String.t) :: module | no_return()
  def fetch!(processor) do
    case fetch(processor) do
      :error -> undefined!(processor)
      {:ok, processor} -> processor
    end
  end

  @spec fetch(String.t) :: {:ok, module} | :error
  def fetch(processor) do
    case processors[processor] do
      nil -> :error
      processor -> {:ok, processor}
    end
  end

  @spec undefined!(any) :: no_return()
  defp undefined!(processor) do
    raise Undefined,
      message: "Processor #{inspect processor} undefined"
  end
end
