defmodule Analysis do
  import Emulation, only: [spawn: 2, send: 2, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Annotation
  import Checker
  import Reconciliation
  import Validator

  defp queue_server do
    queue_server([])
  end

  defp queue_server(queue) do
    receive do
      {sender, {:enq, val}} ->
        queue_server([val] ++ queue)

      {sender, {:deq}} ->
        case queue do
          [] ->
            raise "Queue is empty"

          [head | tail] ->
            send(sender, head)
            queue_server(tail)
        end
    end
  end

  defp processA(server) do
    log_path = "~/pogger/apps/analysis/lib/traces/test1"
    Annotation.init("A", log_path)
    msg_id = "a-enq"
    Annotation.annotate_send(msg_id, byte_size(msg_id), %{A: 0, B: 0})
    send(:server, {:enq, 1})
  end

  defp processB(server) do
    log_path = "~/pogger/apps/analysis/lib/traces/test1"
    Annotation.init("B", log_path)
    msg_id = "b-deq"
    Annotation.annotate_send(msg_id, byte_size(msg_id), %{A: 0, B: 0})
    send(:server, {:deq})

    receive do
      {sender, val} ->
        Annotation.annotate_receive("b-receive", val, %{A: 0, B: 1})
        Annotation.annotate_start_task("b-incr", %{A: 0, B: 2})
        val = val + 1
        Annotation.annotate_end_task("b-incr", %{A: 0, B: 3})
        send(:server, {:enq, val})
        Annotation.annotate_send("b-update", val, %{A: 0, B: 4})
        send(server, :done)
    end
  end

  def basic_send_and_receive do
    Emulation.init()
    spawn(:server, fn -> queue_server end)
    spawn(:a, fn -> processA(:server) end)
    spawn(:b, fn -> processB(whoami()) end)

    case File.mkdir(Path.expand("~/pogger/apps/analysis/lib/traces/test1")) do
      _ -> true
    end
    expectation_path = Path.expand("~/pogger/apps/analysis/lib/expectations-testfiles/test1")
    recognizers = read_expectations_files(expectation_path)
    trace_events = read_trace("test1")
    results = check(recognizers, trace_events)
    IO.puts("#{inspect(results)}")
  after
    Emulation.terminate()
  end

  def check(recognizers, trace_events) do
    check(recognizers, Reconciliation.trace_graph(trace_events), [])
  end

  def check(recognizers, trace_graph, results) do
    case recognizers do
      [] ->
        results

      [head | tail] ->
        dummy_start = Reconciliation.Event.start()
        res = Checker.is_valid(head, dummy_start, trace_graph)
        check(tail, trace_graph, [res] ++ results)
    end
  end

  defp read_trace(fname) do
    trace_path = Path.expand("~/pogger/apps/analysis/lib/traces/#{fname}")
    Reconciliation.combine_trace(trace_path)
  end

  defp read_expectations_files(path) do
    case File.ls(path) do
      {:ok, files} ->
        read_expectations_files(
          Enum.map(files, fn file -> Path.expand("#{path}/#{file}") end),
          []
        )

      {:error, reason} ->
        raise "Failed to read files from #{path}. Reason: #{reason}"
    end
  end

  defp read_expectations_files(files, expectations) do
    case files do
      [] ->
        expectations

      [head | tail] ->
        case File.read(head) do
          {:ok, bin} ->
            read_expectations_files(tail, [Validator.to_recognizer(bin)] ++ expectations)

          {:error, reason} ->
            raise "Failed to read files from #{head}. Reason: #{reason}"
        end
    end
  end
end
