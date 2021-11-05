defmodule Annotation.Path do
  alias __MODULE__

  @derive Jason.Encoder
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

  @derive Jason.Encoder
  @enforce_keys [:name, :timestamp, :ttype]
  defstruct(
    name: nil,
    timestamp: nil,
    ttype: nil
  )

  def init(name, timestamp, ttype) do
    %Task{
      name: name,
      timestamp: timestamp,
      ttype: ttype
    }
  end
end

defmodule Annotation.Notice do
  alias __MODULE__

  @derive Jason.Encoder
  @enforce_keys [:name, :timestamp]
  defstruct(
    name: nil,
    timestamp: nil
  )

  def init(name, timestamp) do
    %Notice{
      name: name,
      timestamp: timestamp
    }
  end
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

  def init(message_type, message_id, message_size, timestamp) do
    %Message{
      message_type: message_type,
      message_id: message_id,
      message_size: message_size,
      timestamp: timestamp
    }
  end
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

  def init(process_name, path_id, clock_value) do
    %TimeStamp{
      process_name: process_name,
      path_id: path_id,
      clock_value: clock_value
    }
  end
end
