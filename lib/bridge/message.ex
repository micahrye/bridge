defmodule Bridge.Message do
  
  @enforce_keys [:endpoint, :uuid, :payload]
  defstruct endpoint: nil, uuid: nil, payload: %{}
  
  def create(endpoint, uuid, %{} = payload) do
    %Bridge.Message{endpoint: endpoint, uuid: uuid, payload: payload}
  end
  
end
