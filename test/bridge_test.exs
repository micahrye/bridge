defmodule BridgeTest do
  use ExUnit.Case
  doctest Bridge

  test "greets the world" do
    assert Bridge.hello() == :world
  end
  
  test "generate uuid" do
    uuid = Bridge.Server.generate_uuid(17)
    assert 17 = String.length(uuid)
  end
  
  
end
