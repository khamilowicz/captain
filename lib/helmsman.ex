defmodule Helmsman do
  @moduledoc """
  Processor composer.

  Helmsman converts processor pipeline specification into pipeline.
  """

  defp processors, do: Application.get_env(Helmsman, :processors, [])

  @spec processor(String.t) :: module
  def processor(processor) do
    processors[processor]
  end
end
