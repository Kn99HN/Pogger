defmodule Reconciliation do

@moduledoc """
This module will reconcile the trace file generated for each process
to a global trace 
"""

import Emulation

def init(path) do 
    combined_trace = 
        File.ls!(path)
            |> Enum.flat_map(fn x -> parse_file(x) end)
end


defp parse_file(file_name) do
    file_path = get_file_path()
    events = 
        File.read!("#{file_path}/#{file_name}")
            |> Jason.decode!()
            |> Map.fetch!("events")
end

defp get_file_path() do
    System.get_env("TRACE_FILES")
end

def sort() do
    combined_trace = init(get_file_path())
    IO.puts("#{inspect(combined_trace)}")
    sorted_trace= 
        combined_trace
            |> Enum.sort(fn x, y -> is_earlier(x, y) end)
    IO.puts("#{inspect(sorted_trace)}")
end

defp is_earlier(event1, event2) do
    clock_val1 = get_timestamp(event1) 
    clock_Val2 = get_timestamp(event2)
    if clock_val1 < clock_Val2 do
        true
    else 
        false
    end
end

defp get_timestamp(event) do
    clock_val = event 
                |> Map.fetch!("timestamp")
                |> Map.fetch!("clock_value")
end

end