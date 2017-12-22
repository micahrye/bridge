defmodule BridgeTest do
  use ExUnit.Case
  doctest Bridge

  alias Bridge.Message


  test "add and get message" do
    {:ok, pid, bridge_uuid} = Bridge.Supervisor.create_bridge()
    msg = Message.create("api/", bridge_uuid, %{magic: "sparkles"})
    result = Bridge.add_message(bridge_uuid, msg)
    assert :ok = result

    result = Bridge.get_message(bridge_uuid)
    msg = elem(result, 1)
    assert "api/" === msg.endpoint
    assert bridge_uuid === msg.uuid
    assert %{magic: "sparkles"} === msg.payload
  end

  test "get message" do

  end

  test "clear message" do

  end

  test "check for response" do

  end

end
