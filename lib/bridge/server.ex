defmodule Bridge.Server do
  use GenServer
  # API
  alias Bridge.Message
  
  # default timeout after which the process will be stopped.
  @timeout 30_000
  @close_after 20
  
  def start_link(uuid) do
    IO.puts "Bridge.Server.start_link called with uuid #{uuid}"
    GenServer.start_link(__MODULE__, :ok, name: via_tuple(uuid))
  end

  def get_messages(uuid) do
    case do_get_message(via_tuple(uuid)) do
      {:error, reason} -> {:error, reason}
      {:ok, response} -> {:ok, response}
    end
  end
  
  defp do_get_message(via) do
    try do 
      message = GenServer.call(via, :get_messages)
      {:ok, message}
    catch 
      {:exit, _} -> {:error, "Process uuid no longer exists"}
    end
  end
  
  def add_message(uuid, %Message{} = msg) do
    GenServer.cast(via_tuple(uuid), {:add_message, msg})
  end
  
  def delayed_message(uuid, message) do
    GenServer.cast(via_tuple(uuid), {:delayed_msg, message})
  end
  
  def clear_messages(uuid) do
    GenServer.cast(via_tuple(uuid), :clear_messages)
  end
      
  def close(uuid) do
    GenServer.cast(via_tuple(uuid), :close)
  end
  
  def response(uuid, timeout \\ 5000) do
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
    # Can turn this into continuous recursion since only called from response/2
    :timer.sleep(10)
    case do_get_message(via_tuple(uuid)) do
      {:error, reason} -> 
        {:error, reason}
      {:ok, response} -> 
        case length(response) do
          x when x <= 0 -> do_check_for_response(uuid)
          _ -> List.first(GenServer.call(via_tuple(uuid), :get_messages))
        end
    end
  end

  defp via_tuple(uuid) do
    {:via, Registry, {:api_bridge_registry, uuid}}
  end

  # SERVER
  
  def init(:ok) do
    Process.flag(:trap_exit, true)
    send(self(), :set_timeout)
    
    state = %Message{endpoint: nil, uuid: nil, payload: %{}}
    {:ok, state}
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, state, state}
  end
  
  def handle_cast({:add_message, new_message}, state) do
    # state is only ever the last message added
    {:noreply, new_message}
  end
  
  def handle_cast({:delayed_msg, new_message}, state) do
    # message will be added as new state after 10s
    Process.send_after(self(), {:delayed_msg, new_message}, 10000)
    {:noreply, state}
  end
  
  def handle_cast(:clear_messages, messages) do
    {:noreply,  %Message{}}
  end
  
  def handle_cast(:close, state) do
    Process.send(self(), :end_process, [])
    {:noreply, %Message{}}
  end
  
  def handle_cast({:close_after, delay}, state) do
    Process.send_after(self(), :end_process, delay)
    {:noreply, %Message{}}
  end
  
  def handle_info(:set_timeout, state) do
    IO.puts "setting timeout to 5 sec"
    Process.send_after(self(), :end_process, @timeout)
    {:noreply, state}
  end
  
  def handle_info(:end_process, state) do
    IO.puts "Process terminating from timeout... }"
    {:stop, :normal, state}
  end
  
  def handle_info({:delayed_msg, new_message}, state) do
    IO.puts "Delayed message received, new_message = #{new_message}"
    {:noreply, new_message}
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
