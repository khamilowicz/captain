defmodule Helmsman do
  use Application

  def start(_, _) do
    Helmsman.Supervisor.start_link
  end
end
