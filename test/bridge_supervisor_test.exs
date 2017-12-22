defmodule BridgeSupervisorTest do
  use ExUnit.Case
  doctest Bridge.Supervisor


  test "supervisor start bridge" do
    {:ok, _pid, uuid_1} = Bridge.Supervisor.create_bridge()
    {:ok, _pid, uuid_2} = Bridge.Supervisor.create_bridge(100)
    assert 17 = String.length(uuid_1)
    assert 17 = String.length(uuid_2)
    assert false === String.equivalent?(uuid_1, uuid_2)
  end

  test "bridge in registry" do
    {:ok, bridge_pid, uuid} = Bridge.Supervisor.create_bridge()
    [{reg_bridge_pid, _}] = Registry.lookup(:api_bridge_registry, uuid)
    assert bridge_pid === reg_bridge_pid
  end

end
