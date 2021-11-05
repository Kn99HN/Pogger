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

    Agent.start_link(fn -> Annotation.Path.init(path_id) end, name: context_name)
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

    task =
      Annotation.Task.init(
        tname,
        timestamp,
        :tstart
      )

    Agent.update(whoami(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_end_task(tname, clock_value) do
    timestamp = get_timestamp(clock_value)

    task =
      Annotation.Task.init(
        tname,
        timestamp,
        :tend
      )

    Agent.update(whoami(), fn path -> add_event(path, [task]) end)
    output()
  end

  def annotate_notice(name, clock_value) do
    timestamp = get_timestamp(clock_value)

    notice =
      Annotation.Notice.init(
        name,
        timestamp
      )

    Agent.update(whoami(), fn path -> add_event(path, [notice]) end)
    output()
  end

  def annotate_send(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)

    send_msg =
      Annotation.Message.init(
        :send,
        message_id,
        message_size,
        timestamp
      )

    Agent.update(whoami(), fn path -> add_event(path, [send_msg]) end)
    output()
  end

  def annotate_receive(message_id, message_size, clock_value) do
    timestamp = get_timestamp(clock_value)

    received_msg =
      Annotation.Message.init(
        :receive,
        message_id,
        message_size,
        timestamp
      )

    Agent.update(whoami(), fn path -> add_event(path, [received_msg]) end)
    output()
  end

  defp output() do
    file = get_file_path()
    path = Agent.get(whoami(), fn path -> path end)
    path_id = Map.get(path, :path_id)
    json_path = Jason.encode!(path)

    case file do
      nil ->
        IO.puts("#{inspect(json_path)}")

      fname ->
        full_fname = "#{fname}/#{path_id}"

        case File.touch!(full_fname) do
          :ok ->
            {:ok, file} = File.open(full_fname, [:write])
            IO.binwrite(file, json_path)
            File.close(file)
        end
    end
  end

  defp read_from_file() do
    file = get_file_path()
    path_id = get_path_id()

    if file != nil do
      full_fname = "#{file}/#{path_id}"
      {:ok, path} = File.read(full_fname)
      decoded_path = Jason.decode!(path)
      IO.puts("#{inspect(decoded_path)}")
    end
  end

  defp get_file_path() do
    System.get_env("TRACE_FILES")
  end

  defp get_timestamp(clock_value) do
    Annotation.TimeStamp.init(
      whoami(),
      get_path_id(),
      clock_value
    )
  end
end
