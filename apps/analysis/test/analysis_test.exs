defmodule AnalysisTest do
  use ExUnit.Case
  doctest Analysis

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
    send(server, {:end, 1})
  end

  defp processB(server) do
    Annotation.init("B")
    msg_id = "b:deq"
    Annotation.annotate_send(msg_id, byte_size(msg_id), 0)
    case receive do
      {sender, val} ->
        Annotation.annotate_receive("b:receive", val, 1)
        Annotation.annotate_task(":incr", 0)
        val = val + 1
        send(sender, {:enq, val})
        Annotation.annotate_send("b:send", val, 2)
    end
  end

  test "basic traces with send and receive" do
    Emulation.init()
  end
end
