defmodule Reconciliation do

@moduledoc """
This module will reconcile the trace file generated for each process
to a global trace 
"""

import Emulation

def combine_trace(path) do 
    combined_trace = 
        File.ls!(path)
            |> Enum.filter(fn x -> !String.starts_with?(x, ".") end)
            |> Enum.flat_map(fn x -> parse_file(x) end)
end


defp parse_file(file_name) do
    file_path = get_file_path()
    file_content = 
        File.read!("#{file_path}/#{file_name}")
            |> Jason.decode!()
    path_id = Map.fetch!(file_content, "path_id")
    events = Map.fetch!(file_content, "events")

end

defp get_file_path() do
    System.get_env("TRACE_FILES")
end

def sort() do
    combined_trace = combine_trace(get_file_path())
    IO.puts("#{inspect(combined_trace)}")
    sorted_trace= 
        combined_trace
            |> Enum.sort(fn x, y -> is_earlier(x, y) end)
    IO.puts("#{inspect(sorted_trace)}")
end

defp make_vectors_equal_length(v1, v2) do
    v1_add = for {k, _} <- v2, !Map.has_key?(v1, k), do: {k, 0}
    Map.merge(v1, Enum.into(v1_add, %{}))
end

def is_earlier(event1, event2) do
    v1 = get_timestamp(event1)
    v2 = get_timestamp(event2)

    v1 = make_vectors_equal_length(v1, v2)
    v2 = make_vectors_equal_length(v2, v1)

    compare_result =
      Map.values(
        Map.merge(v1, v2, fn _k, c1, c2 -> c1 <= c2 end)
      )

    if Enum.any?(compare_result) do
      false
    else 
      true
    end
end

defp get_timestamp(event) do
    clock_val = event 
                |> Map.fetch!("timestamp")
                |> Map.fetch!("clock_value")
end

def trace_graph(events) do
    g = Graph.new 
        |> update_vertices(events)
end

def update_vertices(g, events) do
    if events == [] do
        g
    else
        [head | tail] = events
        g = g 
            |> Graph.add_vertex(head)
            |> Reconciliation.update_edge(head, tail)
        update_vertices(g, tail)    
    end
end 

def update_edge(g, event, events) do
    if events == [] do
        g
    else 
        [head | tail] = events            
        if is_earlier(event, head) do
            g = g |> Graph.add_edge([{event, head}])
        end
        update_edge(g, event, tail)
    end
end

end