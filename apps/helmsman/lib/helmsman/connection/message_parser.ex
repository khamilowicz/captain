defmodule Helmsman.Connection.MessageParser do
  alias Helmsman.Utils

  def build_message(message, %{interface: interface, member: member, path: path, destination: destination}) do
    {sym_signature, parsed_messages} = do_build_message(message)

    DBux.Message.build_method_call(path, interface, member, to_signature(sym_signature), List.wrap(parsed_messages), destination)
  end

  def do_build_message(message) when is_tuple(message) do
    message
    |> Tuple.to_list
    |> Enum.map(&do_build_message/1)
    |> Utils.traverse
  end
  def do_build_message(message) when is_bitstring(message) do
    {:string, %DBux.Value{type: :string, value: message}}
  end
  def do_build_message(message) when is_list(message) do
    {[signature | _], value} =
      message
      |> Enum.map(&do_build_message/1)
      |> Utils.traverse

    {{:array, signature}, %DBux.Value{type: {:array, signature}, value: value}}
  end
  def do_build_message(message) when is_map(message) do
    {[[key_signature, value_signature] | _], values} =
      message
      |> Enum.map(&do_build_message/1)
      |> Utils.traverse

    dict = Enum.map(values, &%DBux.Value{type: :dict_entry, value: &1})

    {{:array, {key_signature, value_signature}}, %DBux.Value{type: {:array, :dict_entry}, value: dict}}
  end

  def to_signature(:string), do: "s"
  def to_signature(signatures) when is_list(signatures), do: Enum.map_join(signatures, &to_signature/1)
  def to_signature({:array, signature}), do: "a" <> to_signature(signature)
  def to_signature({sig1, sig2}), do: "{#{to_signature(sig1)}#{to_signature(sig2)}}"
end
