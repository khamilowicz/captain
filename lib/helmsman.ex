defmodule Helmsman do

  defstruct [:structure, :io, :runner]

  def run(helmsman) do
    options = default_options
    {:ok, connection} = Helmsman.Connection.start_link(options)
    Helmsman.Connection.run(helmsman.runner,
                            :run,
                            [helmsman.structure,
                             helmsman.io.input,
                             helmsman.io.output,
                             %{connection: connection}
                           ])
  end

  def default_options do
    [
      hostname:     "hostname",
      identifier:   "org.example.dbux.MyApp",
      match:        "org.example.dbux.OtherIface",
      request_name: "org.example.dbux.MyApp"
    ]
  end

  def result(connection) do
    Helmsman.Connection.result(connection)
  end

  def read([file: path]) do
    with {:ok, json} <- File.read(path),
    {:ok, structure, io} <- Mapmaker.decode(json)
    do
      {:ok, %__MODULE__{structure: structure, io: io, runner: Mapmaker}}
    else
      {:error, reason} = err -> err
      other -> {:error, other}
    end
  end
end
