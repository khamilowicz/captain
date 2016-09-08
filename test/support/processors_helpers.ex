defmodule Helmsman.ProcessorsHelpers do

  def init_processors(context) do
    {:ok, put_in(context, [:processors], %{})}
  end

  def add_one_to_one_processor(context) do
    {:ok, put_in(context.processors["one.to.one"], Helmsman.Processors.OneToOne)}
  end
  def add_one_to_many_processor(context) do
    {:ok, put_in(context.processors["one.to.many"], Helmsman.Processors.OneToMany)}
  end
  def add_many_to_one_processor(context) do
    {:ok, put_in(context.processors["many.to.one"], Helmsman.Processors.ManyToOne)}
  end
  def add_one_to_two_processor(context) do
    {:ok, put_in(context.processors["one.to.two"], Helmsman.Processors.OneToTwo)}
  end

  def configure_processors(context) do
    Application.put_env(Helmsman, :processors, context.processors)
    :ok
  end
end
