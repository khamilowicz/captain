defmodule Mapmaker.ProcessorsHelpers do

  def init_processors(context) do
    {:ok, put_in(context, [:processors], %{})}
  end

  def add_one_to_one_processor(context) do
    {:ok, put_in(context.processors["one.to.one"], Mapmaker.Processors.OneToOne)}
  end
  def add_one_to_many_processor(context) do
    {:ok, put_in(context.processors["one.to.many"], Mapmaker.Processors.OneToMany)}
  end
  def add_many_to_one_processor(context) do
    {:ok, put_in(context.processors["many.to.one"], Mapmaker.Processors.ManyToOne)}
  end
  def add_one_to_two_processor(context) do
    {:ok, put_in(context.processors["one.to.two"], Mapmaker.Processors.OneToTwo)}
  end

  def configure_processors(context) do
    Application.put_env(Mapmaker, :processors, context.processors)
    Application.put_env(Mapmaker, :postprocessors, context[:postprocessors])
    :ok
  end
end
