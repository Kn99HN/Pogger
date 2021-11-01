defmodule BasicAnnotationTest do
  use ExUnit.Case

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2, whoami: 0, timer: 1]
  import Annotation

  def basic_trace_with_task_annotation do
    Annotation.init("a")
    Annotation.annotate_start_task("1+1", 0)
    x = 1 + 1
    IO.puts("Output: #{inspect(x)}")
    Annotation.annotate_end_task("1+1", 0)
  end

  test "Test basic trace with task annotation" do
    Emulation.init()
    pid = self()
    spawn(:a, basic_trace_with_task_annotation)
  after
    Emulation.terminate()
  end
end
