defmodule Bridge do
  use GenServer
  @moduledoc ~S"""
  Bridge is a generic application that was designed to allow HTTP and
  Websocket (WS) APIs to be combined as if it was only an HTTP
  interface. In the case of systems that might have a public HTTP API and
  private, or otherwise, WS API. Bridge creates a unique process for each
  request that can later be responded to via different code paths and APIS
  to "finish" the initial HTTP request.

  Bridge is a lightweight solution that uses `Registry` for managing unique instances
  of spawned processes. The use of `Registry` allows for local, decentralized
  and scalable key-value process storage. `Bridge` leverages this to create a
  unique name/process for each bridging request. At some point a bridge request
  must recieve a response, or it will timeout.

  The initial bridge request can start a task to continously check for a response.
  If the response is not recieved before the timeout perioud (default 30_000ms)
  the process will timeout and be cleared from the registry.
  """

  alias Bridge.Message

  # default timeout after which the process will be stopped.
  @timeout 30_000
  @close_after 20

  @doc """
  While start_link is part of public API bridge should be used though supervisor
  call `Bridge.Supervisor.create_bridge/2`
  """
  @spec start_link(String.t, integer) :: {:ok, pid}
  def start_link(uuid, timeout \\ @timeout) do
    IO.puts "Bridge.start_link called with uuid #{uuid}"
    GenServer.start_link(__MODULE__, {:ok, timeout}, name: via_tuple(uuid))
  end

  @spec get_message(String.t) :: {:ok, String.t} | {:error, String.t}
  def get_message(uuid) do
    case do_get_message(via_tuple(uuid)) do
      {:error, reason} -> {:error, reason}
      {:ok, response} -> {:ok, response}
    end
  end

  defp do_get_message(via) do
    try do
      # If process DNE will through (EXIT) no process.
      # We catch the exit and move respond with error
      message = GenServer.call(via, :get_messages)
      {:ok, message}
    catch
      # TODO: Try using implicit try/rescue
      :exit, _ -> {:error, "Process uuid no longer exists"}
    end
  end

  @doc """
  Add a `%Bridge.Message` to the bridge identified by uuid

  Returns `:ok` whether or not message actually added, since
  if the bridge has been closed or expired the message will
  not be added.
  """
  @spec add_message(String.t, Bridge.Message.t) :: :ok
  def add_message(uuid, %Message{} = msg) do
    GenServer.cast(via_tuple(uuid), {:add_message, msg})
  end

  @doc """
  Add a `%Bridge.Message` to the bridge identified by uuid

  Returns `:ok` if message added to bridge. Returns :error if
  the bridge does not exist. This will be slower than `Bridge.add_message`
  """
  @spec add_message_with_assurance(String.t, Bridge.Message.t) :: :ok | :error
  def add_message_with_assurance(uuid, %Message{} = msg) do
    case Registry.lookup(:api_bridge_registry, uuid) do
      [] -> :error
      _ -> GenServer.cast(via_tuple(uuid), {:add_message, msg})
    end
  end

  @doc """
  Close a bridge, no message will be recieved.
  """
  @spec close(String.t) :: :ok
  def close(uuid) do
    GenServer.cast(via_tuple(uuid), :close)
  end

  @doc """
  Response async starts a task that continues to check for a response
  for bridge with uuid. 
  """
  @spec response_async(String.t, integer) :: Task.t
  def response_async(uuid, timeout) do
    # Task.async(Bridge, :response, [uuid, timeout])
    Task.async(fn -> response(uuid, timeout) end)
  end

  @spec response(String.t, integer) :: {:ok, term} | {:error, term} | {:timeout, String.t}
  defp response(uuid, timeout \\ 5000) do
    IO.puts "Checking for response."
    task = Task.async(fn -> do_check_for_response(uuid) end)
    IO.puts "Task.yield for #{uuid}"
    case Task.yield(task, timeout) do
      # On any condition close process, since call to close process is before
      # return we must provide a short delay before process exits
      {:ok, response} ->
        GenServer.cast(via_tuple(uuid), {:close_after, @close_after})
        {:ok, response}
      {:exit, reason} ->
        GenServer.cast(via_tuple(uuid), {:close_after, @close_after})
        {:exit, reason}
      nil ->
        GenServer.cast(via_tuple(uuid), {:close_after, @close_after})
        # If we timeout we make sure to kill task
        Task.shutdown(task, :brutal_kill)
        {:timeout, "Bridge response timeout"}
    end
  end

  defp do_check_for_response(uuid) do
    # sleep for 10ms
    :timer.sleep(10)
    case do_get_message(via_tuple(uuid)) do
      {:error, reason} -> {:error, reason}
      # Here we have the bridge with a message with an empty payload.
      # We assume that there has not been a reply and so we keep checking.
      {:ok, response} ->
        case map_size(response.payload) do
          x when x === 0 -> do_check_for_response(uuid)
          _ -> GenServer.call(via_tuple(uuid), :get_messages)
        end
    end
  end

  defp via_tuple(uuid) do
    {:via, Registry, {:api_bridge_registry, uuid}}
  end

  # SERVER
  def init({:ok, timeout}) do
    Process.flag(:trap_exit, true)
    send(self(), {:set_timeout, timeout})

    state = %Message{endpoint: nil, uuid: nil, payload: %{}}
    {:ok, state}
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:add_message, new_message}, _state) do
    # state is only ever the last message added
    {:noreply, new_message}
  end

  def handle_cast(:close, _state) do
    Process.send(self(), :end_process, [])
    {:noreply, %Message{endpoint: nil, uuid: nil, payload: %{}}}
  end

  def handle_cast({:close_after, delay}, _state) do
    Process.send_after(self(), :end_process, delay)
    {:noreply, %Message{endpoint: nil, uuid: nil, payload: %{}}}
  end

  def handle_info({:set_timeout, delay}, state) do
    IO.puts "setting timeout to #{delay} ms"
    Process.send_after(self(), :end_process, delay)
    {:noreply, state}
  end

  def handle_info(:end_process, state) do
    IO.puts "Process terminating from timeout... }"
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _from, :normal}, state) do
    IO.puts "handle_info EXIT"
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _, :process, _pid, _}, state) do
    # When a monitored process dies, we will receive a
    # `:DOWN` message that we can use to remove the
    # dead pid from our registry.
    IO.puts "GOING DOWN"
    {:noreply, state}
  end

  def terminate(reason, state) do
    # Do Shutdown Stuff
    IO.puts "Going Down: reason #{reason} state #{inspect(state)}"
    :ok
  end

end
