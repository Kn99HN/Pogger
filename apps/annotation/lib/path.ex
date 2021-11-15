defmodule Annotation.Path do
  alias __MODULE__

  @derive Jason.Encoder
  @enfore_keys [:path_id]
  defstruct(
    path_id: nil,
    events: []
  )

end

defmodule Annotation.Task do
  
  alias __MODULE__

  @derive Jason.Encoder
  @enforce_keys [:name, :timestamp, :ttype]
  defstruct(
    name: nil,
    timestamp: nil,
    ttype: nil
  )
end

defmodule Annotation.Notice do
  alias __MODULE__

  @derive Jason.Encoder
  @enforce_keys [:name, :timestamp]
  defstruct(
    name: nil,
    timestamp: nil
  )
end

defmodule Annotation.Message do
  alias __MODULE__

  @derive Jason.Encoder
  @enforce_keys [:message_type, :message_id, :message_size, :timestamp]
  defstruct(
    message_type: nil,
    message_id: nil,
    message_size: nil,
    timestamp: nil
  )
end

defmodule Annotation.TimeStamp do
  alias __MODULE__

  @derive Jason.Encoder
  @enforce_keys [:process_name, :path_id, :clock_value]
  defstruct(
    process_name: nil,
    path_id: nil,
    clock_value: nil
  )
end
