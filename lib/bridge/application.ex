defmodule Bridge.Application do
  use Application
  
  def start(_type, _args) do
    import Supervisor.Spec
    
    children = [
      supervisor(Registry, [:unique, :api_bridge_registry]),
      supervisor(Bridge.Supervisor, [])
    ]
    
    opts = [strategy: :one_for_one, name: Bridge.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
end
