defmodule Annotation do
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
    Agent.get(context_name, fn path -> Map.get(path, path_id) end)
  end

  defp add_event(path, entries) do
    %{path | events: entries ++ path.events}
  end

  def start_task(tname, vector_clock_value) do
    timestamp = get_timestamp(clock_value)
    task = %Task {
      name: tname,
      timestamp: timestamp,
      task: nil
    }
    Agent.update(get_context(), fn path -> add_event(path, [task]) end)
  end

  
  def get_context do
    hostname = whoami()
    "#{hostname} anno_context"
  end

  defp get_timestamp(clock_value) do
    %TimeStamp{
      process_name: whoami(),
      path_id: get_path_name(),
      clock_value: clock_value
    }
  end
end
