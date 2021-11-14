defmodule CheckerTest do
  use ExUnit.Case

  test "Basic trace validation on expectations" do
    expectations = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Notice{
            pattern: "A"
          }
        ]
      }
    }

    trace_events = [
      %Reconciliation.Event{
        detail: %{
          "name" => "Starting process A",
          "timestamp" => %{
            "clock_value" => %{"A" => 1, "B" => 0, "C" => 0},
            "path_id" => "A",
            "process_name" => "A"
          }
        },
        path_id: "A",
        event_type: :notice
      }
    ]

    dummy_start = Reconciliation.Event.start()
    trace_graph = Reconciliation.trace_graph(trace_events)

    assert Checker.is_valid(expectations, dummy_start, trace_graph) == true
  end

  test "Trace validation on task expectations" do
    expectations = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Task{
            name: "Starting process A",
            statements: [
              %Validator.Notice{
                pattern: "A"
              },
              %Validator.Send{
                name: "b: send"
              }
            ]
          }
        ]
      }
    }

    trace_events = [
      %Reconciliation.Event{
        detail: %{
          "name" => "Starting process A",
          "timestamp" => %{
            "clock_value" => %{"A" => 1, "B" => 0, "C" => 0},
            "path_id" => "A",
            "process_name" => "A"
          },
          "ttype" => "tstart"
        },
        path_id: "A",
        event_type: :task
      },
      %Reconciliation.Event{
        detail: %{
          "name" => "Process A notice",
          "timestamp" => %{
            "clock_value" => %{"A" => 2, "B" => 0, "C" => 0},
            "path_id" => "A",
            "process_name" => "A"
          }
        },
        path_id: "A",
        event_type: :notice
      },
      %Reconciliation.Event{
        detail: %{
          "message_id" => "b: send",
          "message_size" => 12,
          "message_type" => "send",
          "timestamp" => %{
            "clock_value" => %{"A" => 2, "B" => 1, "C" => 0},
            "path_id" => "B",
            "process_name" => "B"
          }
        },
        path_id: "B",
        event_type: :message
      }
    ]

    dummy_start = Reconciliation.Event.start()
    trace_graph = Reconciliation.trace_graph(trace_events)

    assert Checker.is_valid(expectations, dummy_start, trace_graph) == true
  end

  test "Trace validation on repeat expectations" do
    expectations = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Task{
            name: "Starting process A",
            statements: [
              %Validator.Notice{
                pattern: "A"
              }
            ]
          },
          %Validator.Repeat{
            low: 1,
            high: 3,
            statements: [
              %Validator.Notice{
                pattern: "B"
              }
            ]
          }
        ]
      }
    }

    trace_events = [
      %Reconciliation.Event{
        detail: %{
          "name" => "Starting process A",
          "timestamp" => %{
            "clock_value" => %{"A" => 1, "B" => 0, "C" => 0},
            "path_id" => "A",
            "process_name" => "A"
          },
          "ttype" => "tstart"
        },
        path_id: "A",
        event_type: :task
      },
      %Reconciliation.Event{
        detail: %{
          "name" => "Process A notice",
          "timestamp" => %{
            "clock_value" => %{"A" => 2, "B" => 0, "C" => 0},
            "path_id" => "A",
            "process_name" => "A"
          }
        },
        path_id: "A",
        event_type: :notice
      },
      %Reconciliation.Event{
        detail: %{
          "name" => "Process B notice 1",
          "timestamp" => %{
            "clock_value" => %{"A" => 2, "B" => 1, "C" => 0},
            "path_id" => "B",
            "process_name" => "B"
          }
        },
        path_id: "B",
        event_type: :notice
      },
      %Reconciliation.Event{
        detail: %{
          "name" => "Process B notice 2",
          "timestamp" => %{
            "clock_value" => %{"A" => 2, "B" => 2, "C" => 0},
            "path_id" => "B",
            "process_name" => "B"
          }
        },
        path_id: "B",
        event_type: :notice
      }
    ]

    dummy_start = Reconciliation.Event.start()
    trace_graph = Reconciliation.trace_graph(trace_events)

    assert Checker.is_valid(expectations, dummy_start, trace_graph) == true
  end
end
