defmodule Bridge.Message do
  @moduledoc ~S"""
  Bridge.Message is a struct used for passing messages across the bridge.
  The following keys are enforced: [:endpoint, :uuid, :payload]
  """
  @type t :: %Bridge.Message{endpoint: String.t, uuid: String.t, payload: map}
  @enforce_keys [:endpoint, :uuid, :payload]
  defstruct endpoint: nil, uuid: nil, payload: %{}
  
  @doc ~S"""
  creates a `Bridge.Message` struct
  
  Returns: `Bridge.Message`
  """
  @spec create(String.t, String.t, map) :: Bridge.Message.t
  def create(endpoint, uuid, %{} = payload) do
    %Bridge.Message{endpoint: endpoint, uuid: uuid, payload: payload}
  end
  
end
