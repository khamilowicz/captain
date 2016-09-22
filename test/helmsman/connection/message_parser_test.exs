defmodule Helmsman.MessageParserTest do
  use ExUnit.Case, async: true

  alias Helmsman.Connection.MessageParser
  doctest MessageParser

  describe "build_message builds DBux message" do
    test "from strings" do
      message = "Hello there!"

      assert %DBux.Message{body: [
        %DBux.Value{type: :string, value: message}],
        destination: "dest",
        serial: 0, interface: "interface", member: "member", message_type: :method_call, path: "path", signature: "s"} ==
      MessageParser.build_message(message, %{interface: "interface", member: "member", path: "path", destination: "dest"})
    end

    test "from tuple" do
      message = {"Hello", "there","!" }

      assert %DBux.Message{body: [
        %DBux.Value{type: :string, value: "Hello"},
        %DBux.Value{type: :string, value: "there"},
        %DBux.Value{type: :string, value: "!"},
      ], 
      destination: "dest",
      serial: 0, interface: "interface", member: "member", message_type: :method_call, path: "path", signature: "sss"} ==
                MessageParser.build_message(message, %{interface: "interface", member: "member", path: "path", destination: "dest"})
    end

    test "from array" do
      message = ["Hello", "there","!"]

      assert %DBux.Message{body: [
        %DBux.Value{type: {:array, :string}, value: [
          %DBux.Value{type: :string, value: "Hello"},
          %DBux.Value{type: :string, value: "there"},
          %DBux.Value{type: :string, value: "!"}
        ]}],
        destination: "dest", 
        serial: 0, interface: "interface", member: "member", message_type: :method_call, path: "path", signature: "as"} ==
                MessageParser.build_message(message, %{interface: "interface", member: "member", path: "path", destination: "dest"})
    end

    test "from map" do
      message = %{"a" => "Hello", "b" => "there"}

      assert %DBux.Message{body: [
        %DBux.Value{type: {:array, :dict_entry}, value: [
          %DBux.Value{type: :dict_entry, value: [
            %DBux.Value{type: :string, value: "a"},
            %DBux.Value{type: :string, value: "Hello"},
          ]},
          %DBux.Value{type: :dict_entry, value: [
            %DBux.Value{type: :string, value: "b"},
            %DBux.Value{type: :string, value: "there"},
          ]},
        ]}], 
    destination: "dest",
    serial: 0, interface: "interface", member: "member", message_type: :method_call, path: "path", signature: "a{ss}"} ==
                MessageParser.build_message(message, %{interface: "interface", member: "member", path: "path", destination: "dest"})
    end
  end
end
