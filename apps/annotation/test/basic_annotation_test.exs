defmodule BasicAnnotationTest do
  use ExUnit.Case

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

  def basic_trace_with_task_annotation do
    Annotation.init("a", nil)
    Annotation.annotate_start_task("1+1", 0)
    _x = 1 + 1
    Annotation.annotate_end_task("1+1", 0)
  end

  def basic_trace_with_notice_annotation do
    Annotation.init("b", nil)
    Annotation.annotate_notice("Starting process b", 0)
  end

  def basic_trace_with_send_and_receive_annotation(caller) do
    Annotation.init("c")
    msg = "Hello world!"
    Annotation.annotate_send("c:send", byte_size(msg), 1)
    send(self(), msg)
    receive do
      {_, _, received_m}
        -> 
        Annotation.annotate_receive("c:receive", byte_size(received_m), 2)
        send(caller, :done)
    end
  end

  test "Test trace with basic annotations" do
    Emulation.init()
    pid = self()
    spawn(:a, fn -> basic_trace_with_task_annotation() end)
    spawn(:b, fn -> basic_trace_with_notice_annotation() end)
    spawn(:c, fn -> basic_trace_with_send_and_receive_annotation(pid) end)

    receive do
      :done -> true
    end

  after
    Emulation.terminate()
  end
end
