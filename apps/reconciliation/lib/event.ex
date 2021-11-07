defmodule Reconciliation.Event do
  alias __MODULE__

  @enforce_keys [:path_id, :event_type, :detail]
  defstruct(
    path_id: nil,
    event_type: nil,
    detail: nil
  )

  def init(path_id, event_type, detail) do
    %Event{
      path_id: path_id,
      event_type: event_type,
      detail: detail
    }
  end
end
