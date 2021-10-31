defmodule Annotation do

  import Emulation, only: [whoami: 0]

  @send :send_msg
  @receive :receive_msg

  @moduledoc """
  Documentation for `Annotation`.
  """
  
  
  def init(path_id) do
    context_name = get_context()
    try do
      Agent.stop(context_name)
    catch
      :exit, _ -> true
    end
    
    Agent.start_link(fn -> Path.init(path_id) end, name: context_name)
  end

  def terminate do
    context_name = get_context()
    try do
      Agent.stop(@context_name)
    catch
      :exit, _ -> true
    end
  end

  def get_path_name do
    context_name = get_context()
    Agent.get(context_name, fn path -> Map.get(path, :path_id) end)
  end

  defp add_event(path, entries) do
    %{path | events: entries ++ path.events}
  end

  def annotate_start_task(tname, clock_value) do
    timestamp = get_timestamp(clock_value)
    task = Task.init(
      tname,
      timestamp,
      :tstart
    )
    Agent.update(get_context(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_end_task(tname, clock_value) do
    timestamp = get_timestamp(clock_value)
    task = Task.init(
      tname,
      timestamp,
      :tend
    )
    Agent.update(get_context(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_notice(name, clock_value) do
    timestamp = get_timestamp(clock_value)
    notice = Notice.init(
      name,
      timestamp: timestamp
    )
    Agent.update(get_context(), fn path -> add_event(path, [notice]) end)
    output()
  end

  def annotate_send(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)
    send_msg = Message.init(
      :send,
      message_id,
      message_size,
      timestamp
    )
    Agent.update(get_context(), fn path -> add_event(path, [send_msg]) end)
    output()
  end

  def annotate_receive(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)
    received_msg = Message.init(
      :receive,
      message_id,
      message_size,
      timestamp
    )
    Agent.update(get_context(), fn path -> add_event(path, [received_msg]) end)
    output()
  end

  defp output() do
    file = get_file_path()
    path = Agent.get(get_context(), fn path -> path end)
    json_path = Jason.encode!(path)
    case file do
      nil -> IO.puts("#{inspect(json_path)}")
      fname ->
        full_fname = "#{inspect(fname)}-#{inspect(whoami())}"
        {:ok, file} = File.open(full_fname, [:write])
        IO.binwrite(file, json_path)
        File.close(file)
    end
  end

  defp read_from_file() do
    file = get_file_path()
    if file != nil do
      {:ok, path} = File.read(file)
      decoded_path = Jason.decode!(path)
      IO.puts("#{inspect(decoded_path)}")
    end
  end

  defp get_file_path() do
    System.get_env("TRACE_FILES")
  end

  def get_context do
    hostname = whoami()
    "#{hostname} anno_context"
  end

  defp get_timestamp(clock_value) do
    TimeStamp.init(
      whoami(),
      get_path_name(),
      clock_value
    )
  end
end
