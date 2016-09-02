defmodule Helmsman.Processors do

  defmodule Undefined do
    defexception [:message]
  end

  defp processors, do: Application.get_env(Helmsman, :processors, [])

  @spec fetch!(String.t) :: module | no_return()
  def fetch!(processor) do
    processors[processor] || undefined!(processor)
  end

  @spec undefined!(any) :: no_return()
  defp undefined!(processor) do
    raise Undefined,
      message: "Processor #{inspect processor} undefined"
  end
end
