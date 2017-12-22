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

Start be creating a supervised bridge server. The uuid of bridge
is used for interacting with it.
```
iex> {:ok, pid, uuid} = Bridge.Supervisor.create_bridge()
{:ok, #PID<0.136.0>}
```

You can then add/get messages from the Bridge.Server
```
iex> alias Bridge.Message
:ok
iex> msg = Message.create("api/", uuid, %{data: "stuff"})
:ok
iex> Bridge.add_message(uuid, msg)
:ok
iex> Bridge.get_message(uuid)
{:ok,
 %Bridge.Message{endpoint: "api/", payload: %{data: "stuff"},
  uuid: "wiLsm+Ggs1CrMnHjB"}}
```

If the supervised process crashes the supervisor will restart it
```
iex> Registry.lookup(:api_bridge_registry, uuid) |> List.first() |> elem(0) |> Process.exit(:kill)
true
iex> Bridge.get_message(uuid)
{:error, "Process uuid no longer exists"}
iex> Bridge.add_message(uuid, msg)
:ok
iex> Bridge.get_message(uuid)
{:ok,
 %Bridge.Message{endpoint: "api/", payload: %{data: "stuff"},
  uuid: "wiLsm+Ggs1CrMnHjB"}}
```

We see above that the process is killed automatically restarted, while
it does not retain messages, new messages can be added and then retrieved.

This next example shows how you can create a bridge and then start a task to
listen for a response over that bridge. While here we are simply adding the
message after a second this could be happing in any other process as long
as it has access to the Bridge module.

```
alias Bridge.Message
response_timeout = 20000
{:ok, pid, uuid} = Bridge.Supervisor.create_bridge()
msg = Message.create("api/", uuid, %{data: "more stuff"})
task = Bridge.response_async(uuid, response_timeout)
:timer.sleep(1000)
Bridge.add_message(uuid, msg)
results = Task.await(task)
IO.puts "task result = #{inspect results}"
```

task = Task.async(Bridge, :response, [uuid, response_timeout])
