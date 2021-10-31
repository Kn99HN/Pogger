defmodule Annotation.Path do
  
  alias __MODULE__
  @enfore_keys [:path_id]
  defstruct(
    path_id: nil,
    events: []
  )

  def init(path_id) do
    %Path{
      path_id: path_id,
      events: []
    }
  end
end

defmodule Annotation.Task do
  
  alias __MODULE__
  @enforce_keys [:name, :timestamp]
  defstruct(
    name: name,
    timestamp: nil,
    task: nil
  )
end

defmodule Annotation.Notice do
  alias __MODULE__
  @enforce_keys [:name, :timestamp]
  defstruct(
    name: nil,
    timestamp: nil
  )
end

defmodule Annotation.Message do
  alias __MODULE__
  @enforce_keys [:message_type, :message_id, :message_size, :timestamp]
  defstruct(
    name: nil,
    timestamp: nil,
  )
end

defmodule Annotation.TimeStamp do
  alias __MODULE__
  @enforce_keys [:process_name, :path_id, :clock_value]
  defstruct(
    process_name: nil,
    path_id: nil,
    clock_value: nil
  )
end
