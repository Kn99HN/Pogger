defmodule ReconciliationTest do

use ExUnit.Case
import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

import Emulation, only: [spawn: 2, send: 2]

defp get_file_path() do
    System.get_env("TRACE_FILES")
end

defp test_output_trace_file(fname, content) do
    file = get_file_path()
    json_content = Jason.encode!(content)
    case file do
      nil -> IO.puts("Error generate test trace files")
      fpath ->
        full_fname = "#{fpath}/#{fname}"
        case File.touch!(full_fname) do
          :ok ->
            {:ok, file} = File.open(full_fname, [:write])
            IO.binwrite(file, json_content)
            File.close(file)
        end
    end
end


test "Combine trace file" do

    trace1 = %{"events": [%{"name":  "1+1","timestamp": %{"clock_value": %{a: 2, b: 0, c: 0},"path_id": "a","process_name": "a"},"ttype": "tend"}, 
                        %{"name": "1+1","timestamp": %{"clock_value": %{a: 1, b: 0, c: 0},"path_id": "a","process_name": "a"},"ttype": "tstart"}],"path_id": "a"}
    trace2 = %{"events": [%{"name": "Starting process b","timestamp": %{"clock_value": %{a: 0, b: 1, c: 0},"path_id": "b","process_name": "b"}}],"path_id": "b"}
    trace3 = %{"events": [%{"message_id": "c: receive","message_size": 12,"message_type": "receive","timestamp": %{"clock_value": %{a: 1, b: 0, c: 2},"path_id": "c","process_name": "c"}},
                        %{"message_id": "c: send","message_size": 12,"message_type": "send","timestamp": %{"clock_value": %{a: 1, b: 0, c: 1},"path_id": "c","process_name": "c"}}],"path_id": "c"}
    
    test_output_trace_file("trace1", trace1)
    test_output_trace_file("trace2", trace2)
    test_output_trace_file("trace3", trace3)

    trace_events = Reconciliation.combine_trace(get_file_path())

    IO.puts("#{inspect(trace_events)}")
    assert length(trace_events) == 5
end

test "Generate trace graph" do 
    trace_events = Reconciliation.combine_trace(get_file_path())
    g = Reconciliation.trace_graph(trace_events)
    Graph.edges(g)

    assert true
end

end