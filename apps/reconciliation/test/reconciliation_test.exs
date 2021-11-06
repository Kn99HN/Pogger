defmodule ReconciliationTest do
  use ExUnit.Case

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

  defp test_get_trace_file_path() do
    case Reconciliation.get_file_path() do
      nil ->
        case File.mkdir("../../traces") do
          {:ok} -> "../../traces"
          {:error, :eexist} -> "../../traces"
          {:error, error} -> IO.puts("Unable to create the traces folder with error #{error}")
        end

      default_path ->
        default_path
    end
  end

  defp test_output_trace_file(fname, content) do
    json_content = Jason.encode!(content)

    fpath = test_get_trace_file_path()
    full_fname = "#{fpath}/#{fname}"

    case File.touch!(full_fname) do
      :ok ->
        {:ok, file} = File.open(full_fname, [:write])
        IO.binwrite(file, json_content)
        File.close(file)
    end
  end

  test "Combine trace file" do
    trace1 = %{
      events: [
        %{
          name: "1+1",
          timestamp: %{clock_value: %{a: 2, b: 0, c: 0}, path_id: "a", process_name: "a"},
          ttype: "tend"
        },
        %{
          name: "1+1",
          timestamp: %{clock_value: %{a: 1, b: 0, c: 0}, path_id: "a", process_name: "a"},
          ttype: "tstart"
        }
      ],
      path_id: "a"
    }

    trace2 = %{
      events: [
        %{
          name: "Starting process b",
          timestamp: %{clock_value: %{a: 0, b: 1, c: 0}, path_id: "b", process_name: "b"}
        }
      ],
      path_id: "b"
    }

    trace3 = %{
      events: [
        %{
          message_id: "c: receive",
          message_size: 12,
          message_type: "receive",
          timestamp: %{clock_value: %{a: 1, b: 0, c: 2}, path_id: "c", process_name: "c"}
        },
        %{
          message_id: "c: send",
          message_size: 12,
          message_type: "send",
          timestamp: %{clock_value: %{a: 1, b: 0, c: 1}, path_id: "c", process_name: "c"}
        }
      ],
      path_id: "c"
    }

    test_output_trace_file("trace1", trace1)
    test_output_trace_file("trace2", trace2)
    test_output_trace_file("trace3", trace3)

    trace_events = Reconciliation.combine_trace(test_get_trace_file_path())
    assert length(trace_events) == 5
  end

  test "Generate trace graph" do
    trace_events = Reconciliation.combine_trace(test_get_trace_file_path())
    g = Reconciliation.trace_graph(trace_events)
    IO.puts("#{inspect(g)}")
    
    assert Graph.num_vertices(g) == 5
    assert Graph.num_edges(g) == 4

  end
end
