defmodule Bridge.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # :unique option means that each key will point to a unique value
      supervisor(Registry, [:unique, :api_bridge_registry]),
      supervisor(Bridge.Supervisor, [])
    ]

    # I give the Bridge.Supervisor a :one_for_one strategy. This means that
    # if a child process terminates, only that process is restarted.
    #
    # I also include :max_restarts and :max_seconds with their default values.
    # I find it helpful to include them for explicitness and reminder of how
    # the supervisor behaves.
    opts = [
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 5,
      name: Bridge.Supervisor
    ]
    Supervisor.start_link(children, opts)
  end

end
