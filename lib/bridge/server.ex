defmodule Bridge.Server do
  use GenServer
  
  # API

  def start_link(endpoint) do
    IO.puts "Bridge.Server.start_link called"
    GenServer.start_link(__MODULE__, [], name: via_tuple(endpoint))
  end

  # def add_message(pid, message) do
  #   GenServer.cast(pid, {:add_message, message})
  # end
  # 
  # def get_messages(pid) do
  #   GenServer.call(pid, :get_messages)
  # end
  
  def add_message(endpoint, message) do
    GenServer.cast(via_tuple(endpoint), {:add_message, message})
  end
  
  def delayed_message(endpoint, message) do
    GenServer.cast(via_tuple(endpoint), {:delayed_msg, message})
  end

  def get_messages(endpoint) do
    GenServer.call(via_tuple(endpoint), :get_messages)
  end
  
  def response(endpoint, times \\ 0) do
    
    task = Task.async(fn -> do_check_for_response(endpoint, true) end)
    # result = Task.await(task, 5000)
    task_result = case Task.yield(task, 3000) do
      {:ok, response} -> response
      {:exit, reason} -> 
        "Check messages exited for reason = #{reason}"
      nil -> 
        # If we timeout we make sure to kill task
        IO.puts "Yield timeout"
        Task.shutdown(task, :brutal_kill)
        {:timeout, "Bridge response timeout"}
    end
    IO.puts "Task result #{inspect task_result}"
  end
  
  defp do_check_for_response(endpoint, times) when is_integer(times) do
    # Can turn this into continuous recursion since only called
    # from response/2
    case times do
      x when x > 0 -> 
        IO.puts(GenServer.call(via_tuple(endpoint), :get_messages))
        :timer.sleep(1000)
        do_check_for_response(endpoint, x - 1)
      _ -> 
        IO.puts "zero times"
        GenServer.call(via_tuple(endpoint), :get_messages)
    end
  end
  
  defp do_check_for_response(endpoint, check) when is_boolean(check) do
    # Can turn this into continuous recursion since only called
    # from response/2
    cond do
      check == true -> 
        IO.puts "checking true"
        num_msgs = length(GenServer.call(via_tuple(endpoint), :get_messages))
        case num_msgs do
          x when x <= 0 -> do_check_for_response(endpoint, true)
          _ -> List.first(GenServer.call(via_tuple(endpoint), :get_messages))
        end
      check == false -> 
        IO.puts "stopping checking for response"
    end
  end

  
  defp via_tuple(endpoint) do
    {:via, Registry, {:api_bridge_registry, endpoint}}
  end

  # SERVER

  def init(messages) do
    Process.flag(:trap_exit, true)
    # send(self(), :set_timeout)
    
    {:ok, messages}
  end

  def handle_cast({:add_message, new_message}, messages) do
    {:noreply, [new_message | messages]}
  end
  
  def handle_cast({:delayed_msg, new_message}, messages) do
    IO.puts "adding delayed message in 10 sec"
    Process.send_after(self(), {:delayed_msg, new_message}, 10000)
    {:noreply, messages}
  end

  def handle_call(:get_messages, _from, messages) do
    {:reply, messages, messages}
  end
  
  def handle_info(:set_timeout, state) do
    IO.puts "setting timeout to 5 sec"
    Process.send_after(self(), :end_process, 5000)
    {:noreply, state}
  end
  
  def handle_info(:end_process, state) do
    IO.puts "Process terminating from timeout... }"
    {:stop, :normal, state}
  end
  
  def handle_info({:delayed_msg, new_message}, state) do
    IO.puts "Delayed message received, new_message = #{new_message}"
    {:noreply, [new_message | state]}
  end
  
  def handle_info({:EXIT, _from, :normal}, state) do
    IO.puts "handle_info EXIT"
    {:stop, :normal, state}
  end
  
  def end_process(pid) do
    Process.exit(pid, :normal)
  end
  
  # def terminate(reason, state) do
  #   # Do Shutdown Stuff
  #   IO.puts "Going Down: reason #{reason} state #{inspect(state)}"
  #   :ok
  # end
  
end
