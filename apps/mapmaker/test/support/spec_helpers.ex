defmodule Mapmaker.SpecHelpers do
  defmodule DoNothing do
    def run(input, _extra) do
      send self, {__MODULE__, input}
      {:ok, input}
    end
  end

  defmodule OneToOne do

    def run(%{"in1" => in1} = input, extra) do
      send self, {:processor_called, __MODULE__, input}
      {:ok, %{"out1" =>  in1 <> "a"}}
    end
  end

  defmodule AsyncOneToOne do

    def run(%{"in1" => in1} = input, _extra) do
      this = self
      Mapmaker.ProcessingTask.run(fn ->
        time = 10 + :rand.uniform(11)
        Process.sleep(time)
        send this, {:processor_called, __MODULE__, input}
        {:ok, %{"out1" =>  in1 <> "a"}}
      end)
    end
  end

  defmodule FailingOneToOne do

    def run(%{"in1" => _in1} = input, _extra) do
      send self, {:processor_called, __MODULE__, input}
      throw("Important error")
    end
  end

  defmodule OneToTwo do

    def run(%{"in1" => in1} = input, _extra) do
      send self, {:processor_called, __MODULE__, input}
      {:ok, %{"out1" =>  in1 <> "l", "out2" => in1 <> "r"}}
    end
  end

  defmodule TwoToOne do
    def run(%{"in1" => in1, "in2" => in2} = input, _extra) do
      send self, {:processor_called, __MODULE__, input}
      {:ok, %{"out1" =>  in1 <> in2 <> "c"}}
    end

  end

  defmodule OneToVariable do
    def run(%{"in1" => in1} = input, _extra) do
      send self, {:processor_called, __MODULE__, input}
      {:ok, %{"outN" => [%{"out1" =>  in1 <> "v"}, %{"out1" =>  in1 <> "v"}, %{"out1" =>  in1 <> "v"}] }}
    end
  end

  defmodule VariableToOne do
    def run(%{"inN" => inN} = input, _extra) do
      send self, {:processor_called, __MODULE__, input}
      result = Enum.reduce(inN, "", fn(curr, acc) -> acc <> curr["in1"] end)
      {:ok, %{"out1" =>  result <> "r" }}
    end
  end

  alias Mapmaker.{Spec, Pipeable}
  alias Mapmaker.Reducers.Mapping

  def one_to_one_raw_spec(context) do
    raw_spec = %{
      "processor" => "one.to.one",
      "input" => %{"in1" => "a"},
      "output" => %{"out1" => "b"},
    }
    {:ok, Map.put(context, :one_to_one_spec, raw_spec)}
  end

  def one_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToOne)
      |> Pipeable.put_input("in1", "a")
      |> Pipeable.put_output("out1", "b")

    {:ok, Map.put(context, :one_to_one_spec, spec)}
  end

  def async_one_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(AsyncOneToOne)
      |> Pipeable.put_input("in1", "a")
      |> Pipeable.put_output("out1", "b")

    {:ok, Map.put(context, :async_one_to_one_spec, spec)}
  end

  def one_to_two_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToTwo)
      |> Pipeable.put_input("in1", "b")
      |> Pipeable.put_output("out1", "c")
      |> Pipeable.put_output("out2", "d")

    {:ok, Map.put(context, :one_to_two_spec, spec)}
  end

  def two_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(TwoToOne)
      |> Pipeable.put_input("in1", "c")
      |> Pipeable.put_input("in2", "d")
      |> Pipeable.put_output("out2", "e")

    {:ok, Map.put(context, :two_to_one_spec, spec)}
  end

  def one_to_variable_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(OneToVariable)
      |> Pipeable.put_input("in1", "a")
      |> Pipeable.put_output("outN", "b")

    {:ok, Map.put(context, :one_to_variable_spec, spec)}
  end

  def variable_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(VariableToOne)
      |> Pipeable.put_input("inN", "a")
      |> Pipeable.put_output("out1", "b")

    {:ok, Map.put(context, :variable_to_one_spec, spec)}
  end

  def failing_one_to_one_spec(context) do
    spec =
      %Spec{}
      |> Spec.put_processor(FailingOneToOne)
      |> Pipeable.put_input("in1", "a")
      |> Pipeable.put_output("out1", "b")

    {:ok, Map.put(context, :failing_one_to_one_spec, spec)}
  end

  def map_reducer_spec(context) do
    spec =
      %Mapping{}
      |> Pipeable.put_input("inN", "a")
      |> Pipeable.put_output("outN", "b")

    {:ok, Map.put(context, :map_reducer_spec, spec)}
  end

end
