defmodule Annotation do

  import Emulation, only: [whoami: 0]

  @moduledoc """
  Documentation for `Annotation`.
  """
  
  
  def init(path_id) do
    context_name = whoami()
    try do
      Agent.stop(context_name)
    catch
      :exit, _ -> true
    end
    Agent.start_link(fn -> %Annotation.Path{ 
      path_id: path_id
    } end, name: context_name)
  end

  def terminate do
    context_name = whoami()
    try do
      Agent.stop(context_name)
    catch
      :exit, _ -> true
    end
  end

  def get_path_id do
    context_name = whoami()
    Agent.get(context_name, fn path -> Map.get(path, :path_id) end)
  end

  defp add_event(path, entries) do
    %{path | events: entries ++ path.events}
  end

  def annotate_start_task(tname, clock_value) do
    timestamp = get_timestamp(clock_value)
    task = %Annotation.Task{
      name: tname,
      timestamp: timestamp,
      ttype: :tstart
    }
    Agent.update(whoami(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_end_task(tname, clock_value) do
    timestamp = get_timestamp(clock_value)
    task = %Annotation.Task{
      name: tname,
      timestamp: timestamp,
      ttype: :tend
    }
    Agent.update(whoami(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_notice(name, clock_value) do
    timestamp = get_timestamp(clock_value)
    notice = %Annotation.Notice{
      name: name,
      timestamp: timestamp
    }
    Agent.update(whoami(), fn path -> add_event(path, [notice]) end)
    output()
  end

  def annotate_send(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)
    send_msg = %Annotation.Message{
      message_type: :send,
      message_id: message_id,
      message_size: message_size,
      timestamp: timestamp
    }
    Agent.update(whoami(), fn path -> add_event(path, [send_msg]) end)
    output()
  end

  def annotate_receive(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)
    received_msg = %Annotation.Message{
      message_type: :receive,
      message_id: message_id,
      message_size: message_size,
      timestamp: timestamp
    }
    Agent.update(whoami(), fn path -> add_event(path, [received_msg]) end)
    output()
  end

  defp output do
    file = get_file_path()
    path = Agent.get(whoami(), fn path -> path end)
    path_id = Map.get(path, :path_id)
    json_path = Jason.encode!(path)
    case file do
      nil -> IO.puts("#{inspect(json_path)}")
      fname ->
        full_fname = "#{fname}/#{path_id}"
        abs_path = Path.expand(full_fname)
        case File.touch!(abs_path) do
          :ok ->
            {:ok, file} = File.open(abs_path, [:write])
            IO.binwrite(file, json_path)
            File.close(file)
        end
    end
  end

  defp read_from_file do
    file = get_file_path()
    path_id = get_path_id()
    if file != nil do
      full_fname = "#{file}/#{path_id}"
      abs_path = Path.expand(full_fname)
      {:ok, path} = File.read(abs_path)
      decoded_path = Jason.decode!(path)
      IO.puts("#{inspect(decoded_path)}")
    end
  end

  defp get_file_path do
    System.get_env("TRACE_FILES")
  end

  defp get_timestamp(clock_value) do
    %Annotation.TimeStamp{
      process_name: whoami(),
      path_id: get_path_id(),
      clock_value: clock_value
    }
  end
end
