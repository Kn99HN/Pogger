defmodule Validator.Recognizer do
  alias __MODULE__

  defstruct(name: nil, map: Map.new())
end

defmodule Validator.Notice do
  alias __MODULE__

  @enforce_keys [:pattern]
  defstruct(pattern: nil)
end

defmodule Validator.Send do
  alias __MODULE__

  @enforce_keys [:name]
  defstruct(name: nil)
end

defmodule Validator.Receive do
  alias __MODULE__

  @enforce_keys [:name]
  defstruct(name: nil)
end

defmodule Validator.Task do
  alias __MODULE__

  @enforce_keys [:name]
  defstruct(name: nil, statements: [])
end

defmodule Validator.Repeat do
  alias __MODULE__

  # Maybe is a Repeat from 0 to 1
  @enforce_keys [:low, :high]
  defstruct(low: 0, high: 1, statements: [])
end
