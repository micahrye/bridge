defmodule Bridge.Supervisor do
  @moduledoc ~S"""
  The `Bridge.Supervisor` is responsible for initialzing and starting a `Bridge`.
  """

  use Supervisor

  @uuid_length 17

  @doc """
  Start the supervisor which is also being supervised by the application.
  """
  def start_link do
    IO.puts "start_link of Bridge.Supervisor"
    Supervisor.start_link(__MODULE__, [], name: :api_bridge_supervisor)
  end

  @doc """
  Primary interface for creating a new `Bridge`. Parameter `timeout` is optional,
  values less than zero are invalid and will result in use of Bridge default
  timeout setting.
  """
  @spec create_bridge(integer) :: {:ok, pid, String.t} | {:error, term}
  def create_bridge(timeout \\ -1) do
    IO.puts "create_bridge of Bridge.Supervisor"
    uuid = generate_uuid()
    if timeout >= 0 do
      # timeout passed to `Bridge.start_link/2` which overwrites the
      # default timeout of the Bridge.
      case Supervisor.start_child(:api_bridge_supervisor, [uuid, timeout]) do
        {:ok, pid} -> {:ok, pid, uuid}
        {:error, msg} -> {:error, msg}
      end
    else
      case Supervisor.start_child(:api_bridge_supervisor, [uuid]) do
        {:ok, pid} -> {:ok, pid, uuid}
        {:error, msg} -> {:error, msg}
      end
    end
    # cond do
    #   timeout < 0 ->
    #     case Supervisor.start_child(:api_bridge_supervisor, [uuid]) do
    #       {:ok, pid} -> {:ok, pid, uuid}
    #       {:error, msg} -> {:error, msg}
    #     end
    #   timeout >= 0 ->
    #     # timeout passed to `Bridge.start_link/2` which overwrites the
    #     # default timeout of the Bridge.
    #     case Supervisor.start_child(:api_bridge_supervisor, [uuid, timeout]) do
    #       {:ok, pid} -> {:ok, pid, uuid}
    #       {:error, msg} -> {:error, msg}
    #     end
    # end
  end

  @spec create_bridge(none) :: String.t
  defp generate_uuid do
      @uuid_length
      |> :crypto.strong_rand_bytes()
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
    # no process is started during the Supervisor initialization,
    # the process will start when we call `Supervisor.start_child/2`
    supervise(children, strategy: :simple_one_for_one)
  end

end
