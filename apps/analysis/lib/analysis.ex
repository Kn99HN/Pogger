defmodule Analysis do
  import Emulation, only: [spawn: 2, send: 2, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Annotation
  import Checker
  import Reconciliation
  import Validator

  defp queue_server(time, log_path) do
    me = whoami()
    Annotation.init("server", log_path)
    Annotation.annotate_start_task("#{me}-start", time)
    queue_server([], time, log_path)
  end

  defp queue_server(queue, time, log_path) do
    me = whoami()
    receive do
      {sender, {{:enq, val}, time_received}} ->
        time_current = update_vetor_clock(me, time)
        time = combine_vector_clock(time_current, time_received)
        Annotation.annotate_receive("#{sender}-enq", 0, time)
        queue_server([val] ++ queue, time, log_path)

      {sender, {{:deq}, time_received}} ->
        time_current = update_vetor_clock(me, time)
        time = combine_vector_clock(time_current, time_received)
        Annotation.annotate_receive("#{sender}-deq", 0, time)

        case queue do
          [] ->
            time = update_vetor_clock(me, time)
            send(sender, {:empty, time})
            Annotation.annotate_send("#{me}-send-empty", 0, time)
            queue_server(queue, time, log_path)

          [head | tail] ->
            time = update_vetor_clock(me, time)
            send(sender, {head, time})
            Annotation.annotate_send("#{me}-send-#{head}", 0, time)
            queue_server(tail, time, log_path)
        end
    end
  end

  defp processA(server, time) do
    log_path = "~/pogger/apps/analysis/lib/traces/test1"
    me = whoami()
    Annotation.init("A", log_path)
    msg_id = "a-enq"
    time = update_vetor_clock(me, time)
    Annotation.annotate_send(msg_id, byte_size(msg_id), time)
    send(:server, {{:enq, 1}, time})
    send(:b, {:start_deq, time})
  end

  defp processB(server, time) do
    me = whoami()
    receive do
      {sender, {:start_deq, time_received}} ->
        log_path = "~/pogger/apps/analysis/lib/traces/test1"
        Annotation.init("B", log_path)
        msg_id = "b-deq"
        time_current = update_vetor_clock(me, time)
        time = combine_vector_clock(time_current, time_received)
        Annotation.annotate_send(msg_id, byte_size(msg_id), time)
        send(:server, {{:deq}, time})
        processB(server, time)

      {sender, {val, time_received}} ->
        time_current = update_vetor_clock(me, time)
        time = combine_vector_clock(time_current, time_received)
        Annotation.annotate_receive("b-receive", val, time)
        time = update_vetor_clock(me, time)
        Annotation.annotate_start_task("b-incr", time)
        val = val + 1
        time = update_vetor_clock(me, time)
        Annotation.annotate_end_task("b-incr", time)
        time = update_vetor_clock(me, time)
        Annotation.annotate_send("b-update", val, time)
        send(:server, {{:enq, val}, time})
        send(server, true)
    end
  end

  def basic_send_and_receive do
    Emulation.init()
    parent = self()
    time = %{server: 0, a: 0, b: 0}

    case File.mkdir(Path.expand("~/pogger/apps/analysis/lib/traces/test1")) do
          _ -> true
    end
    case File.mkdir_p(Path.expand("~/pogger/apps/analysis/lib/expectations-testfiles/test1")) do
          _ -> true
    end
    server_log_path = "~/pogger/apps/analysis/lib/traces/test1"

    spawn(:server, fn -> queue_server(time, server_log_path) end)
    spawn(:a, fn -> processA(:server, time) end)
    spawn(:b, fn -> processB(parent, time) end)

    receive do
      true ->
        expectation_path = Path.expand("~/pogger/apps/analysis/lib/expectations-testfiles/test1")
        res = read_expectations_files(expectation_path)
        recognizers = res |> Enum.map(fn rec -> Map.get(rec, :expectation) end)
        IO.puts("Expectation: #{inspect(recognizers)}")
        files = res |> Enum.map(fn rec -> Path.basename(Map.get(rec, :file)) end)
        trace_events = read_trace("test1")
        IO.puts("Trace: #{inspect(trace_events)}")
        results = Enum.zip([Enum.reverse(files), check(recognizers, trace_events)])
        IO.puts("#{inspect(results)}")
    end
  after
    Emulation.terminate()
  end

  defp processC(time) do
      log_path = "~/pogger/apps/analysis/lib/traces/test2"
      Annotation.init("C", log_path)
      me = whoami()
      time = update_vetor_clock(me, time)
      Annotation.annotate_send("c-enq", 0, time)
      send(:server, {{:enq, 1}, time})
  end

  defp processD(caller, time) do
      log_path = "~/pogger/apps/analysis/lib/traces/test2"
      Annotation.init("D", log_path)
      me = whoami()
      time = update_vetor_clock(me, time)
      Annotation.annotate_send("d-enq", 0, time)
      send(:server, {{:enq, 2}, time})
      send(caller, true)
  end

  def nonsequentail_send_and_receive do
    Emulation.init()
    parent = self()
    time = %{server: 0, c: 0, d: 0}

    case File.mkdir_p(Path.expand("~/pogger/apps/analysis/lib/traces/test2")) do
          _ -> true
    end
    case File.mkdir_p(Path.expand("~/pogger/apps/analysis/lib/expectations-testfiles/test2")) do
          _ -> true
    end
    server_log_path = "~/pogger/apps/analysis/lib/traces/test2"

    spawn(:server, fn -> queue_server(time, server_log_path) end)
    spawn(:c, fn -> processC(time) end)
    spawn(:d, fn -> processD(parent, time) end)
    receive do
      true ->
        expectation_path = Path.expand("~/pogger/apps/analysis/lib/expectations-testfiles/test2")
        res = read_expectations_files(expectation_path)
        recognizers = res |> Enum.map(fn rec -> Map.get(rec, :expectation) end)
        IO.puts("Expectation: #{inspect(recognizers)}")
        files = res |> Enum.map(fn rec -> Path.basename(Map.get(rec, :file)) end)
        trace_events = read_trace("test2")
        IO.puts("Trace: #{inspect(trace_events)}")

        results = Enum.zip([Enum.reverse(files), check(recognizers, trace_events)])
        IO.puts("#{inspect(results)}")
        true
    end
  after
    Emulation.terminate()
  end

  defp combine_vector_clock(current, received) do
    Map.merge(current, received, fn _k, c, r -> max(c, r) end)
  end

  defp update_vetor_clock(process, time) do
    Map.update(time, process, 0, fn c -> c + 1 end)
  end

  def check(recognizers, trace_events) do
    graph = Reconciliation.trace_graph(trace_events)
    check(recognizers, graph, [])
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
            recognizer = Validator.to_recognizer(bin)

            read_expectations_files(
              tail,
              [%{expectation: Validator.to_recognizer(bin), file: head}] ++ expectations
            )

          {:error, reason} ->
            raise "Failed to read files from #{head}. Reason: #{reason}"
        end
    end
  end
end
