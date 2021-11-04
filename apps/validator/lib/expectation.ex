defmodule Expectation.Notice do
  alias __MODULE__

  @enforce_keys [:pattern]
  defstruct(pattern) do
    %Notice{
      pattern: pattern
    }
  end
end

defmodule Expectation.Send do
  alias __MODULE__
  
  @enforce_keys [:pname]
  defstruct(pname, size) do
    %Send{
      pname: pname,
      size: size
    }
  end
end

defmodule Expectation.Receive do
  alias __MODULE__

  @enforce_keys [:pname]
  defstruct(pname, size) do
    %Receive{
      pname: pname,
      size: size
    }
  end
end

defmodule Expectation.Task do
  alias __MODULE__

  @enforce_keys [:tname]
  defstruct(tname, ttype) do
    %Task{
      tname: tname,
      ttype: ttype,
      subtasks: []
    }
  end
end

defmodule Expectation.Repeat do
  alias __MODULE__

  # Maybe is a Repeat from 0 to 1
  @enforce_keys [:low, :high, :statement]
  defstruct(low, high, statement) do
    %Repeat{
      low: low,
      high: high,
      statement: statement
    }
  end
end
