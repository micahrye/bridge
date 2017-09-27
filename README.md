# Bridge

Bridge is an API bridge registry designed to enable communication between
HTTP and Websocket (WS) endpoints. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bridge` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bridge, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bridge](https://hexdocs.pm/bridge).

# Usage
```
$ iex -S mix
```
This will start the the application supervision tree defined in "lib/bridge/application.ex" The bridge server is a supervised process. 

Start be creating a supervised bridge server
```
iex> Bridge.Supervisor.start_bridge("api/gateway")
{:ok, #PID<0.136.0>}
```

You can then add/get messages from the Bridge.Server 
```
iex> Bridge.Server.add_message("api/gateway", "get_config")
:ok
iex> Bridge.Server.add_message("api/gateway", "active_process")
:ok
iex> Bridge.Server.get_messages("api/gateway")
["active_process", "get_config", "current_process"]
```

If the supervised process crashes the supervisor will restart it
```
iex> Registry.lookup(:api_bridge_registry, "api/gateway") |> List.first() |> elem(0) |> Process.exit(:kill)
true
iex> Bridge.Server.get_messages("api/gateway")
[]
iex> Bridge.Server.add_message("api/gateway", "active_process")
Bridge.Server.get_messages("api/gateway")
["active_process"]
```

Bridge.Supervisor.start_bridge("api/driver")
response_timeout = 3000
task = Task.async(Bridge.Server, :response, ["api/gateway", response_timeout])
Bridge.Server.add_message("api/gateway", "someone left a message for you!")
Task.await(task)


We see above that the process is killed automatically restarted, but 
it does not retain messages. New messages can be added and retrieved. 

Future version of this application will retain messages in cases of a
none :normal exit. 
