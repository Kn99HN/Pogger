defmodule Analysis do
  import Emulation, only: [spawn: 2]
  import Annotation
  import Checker
  import Reconciliation
  import Recognizer


  defp queue_server do 
    queue_server([])
  end

  defp queue_server(queue) do
    case receive do
      {sender, {:enq, val} ->
        queue_server([val] ++ queue)
      {sender, {:deq}} ->
        case queue do
          [] -> raise "Queue is empty"
          [head | tail] ->
            send(sender, head)
            queue_server(tail)
        end
    end
  end

  defp processA(server) do
    Annotation.init("A")
    msg_id = "a:enq"
    Annotation.annotate_send(msg_id, byte_size(msg_id), 0)
    send(server, {:enq, 1})
  end

  defp processB(server) do
    Annotation.init("B")
    msg_id = "b:deq"
    Annotation.annotate_send(msg_id, byte_size(msg_id), 0)
    case receive do
      {sender, val} ->
        Annotation.annotate_receive("b:receive", val, 1)
        Annotation.annotate_task("b:incr", 0)
        val = val + 1
        send(sender, {:enq, val})
        Annotation.annotate_send("b:update", val, 2)
    end
  end

  test "basic traces with send and receive" do
    Emulation.init()
    # spawn new processes
    # read expectation file
    # read trace files 
    # call checker on each one
    spawn(:server, fn -> queue_server end)
    spawn(:a, fn -> processA(:server) end)
    spawn(:b, fn -> processB(:server) end)

    recognizers = read_expectation_files("./expectation-testfiles/test1")
    trace_events = read_trace("test1/trace.txt")
    results = check(recognizers, trace_events)

    IO.puts("#{inspect(results)}")
  end

  defp check(recognizers, trace_events) do
    check(recognizers, Reconciliation.trace_graph(trace_events), [])
  end

  defp check(recognizers, trace_graph, results) do
    case recognizers do
      [] -> results
      [head | tail] ->
        dummy_start = Reconciliation.Event.start()
        res = Checker.is_valid(head, dummy_start, trace_graph)
        check(recognizers, trace_graph, [res] ++ results)
    end
  end

  defp read_trace(fname) do
    Reconciliation.parse_file("./traces", fname)
  end

  defp read_expectations_files(path) do
    {:ok, files} = File.ls(path)
    read_expectations_files(files, [])
  end

  defp read_expectations_files(files, expectations) do
    case files do
      [] -> expectations
      [head | tail] ->
        {:ok, bin} = File.read(head)
        read_expectations_files(tail, [Validator.to_recognizer(bin)] ++ expectations)
    end
  end

end
