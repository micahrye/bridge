defmodule Bridge.Supervisor do
  use Supervisor
  
  @uuid_length 17
  
  @doc """
  Start the supervisor
  """
  def start_link do
    IO.puts "start_link of Bridge.Supervisor"
    Supervisor.start_link(__MODULE__, [], name: :api_bridge_supervisor)
  end
  
  def start_bridge(timeout \\ nil) do
    IO.puts "start_bridge of Bridge.Supervisor"
    uuid = generate_uuid()
    cond do
      timeout === nil -> 
        case Supervisor.start_child(:api_bridge_supervisor, [uuid]) do
          {:ok, pid} -> {:ok, pid, uuid}
          {:error, msg} -> {:error, msg}
        end
      timeout >= 0 -> 
        case Supervisor.start_child(:api_bridge_supervisor, [uuid, timeout]) do
          {:ok, pid} -> {:ok, pid, uuid}
          {:error, msg} -> {:error, msg}
        end
    end
  end
  
  defp generate_uuid do
    :crypto.strong_rand_bytes(@uuid_length) 
      |> Base.encode64 
      |> binary_part(0, @uuid_length)
  end
  
  def init(_) do
    children = [
      # defining a restart: strategy of :transient allows for the process
      # to be stoped and not restarted by the supervisor when exiting the
      # process using :normal
      worker(Bridge, [], restart: :transient)
    ]
    
    # We also changed the `strategy` to `simple_one_for_one`.
    # With this strategy, we define just a "template" for a child,
    # no process is started during the Supervisor initialization, just
    # when we call `start_child/2`
    supervise(children, strategy: :simple_one_for_one)
  end
  
end
