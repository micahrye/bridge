defmodule BridgeMessageTest do
  use ExUnit.Case
  doctest Bridge.Message


  test "create bridge message" do
    message = Bridge.Message.create(
      "ws://example.com",
      "87934", %{data:
      [1, 2, 3]})
    assert "ws://example.com" = message.endpoint
    assert "87934" = message.uuid
    assert %{data: [1, 2, 3]} = message.payload
  end

end
