defmodule Checker do
  @moduledoc """
  This module takes in the trace graph together with the expectation to check 
  if there is any valid matching
  """

  @spec is_valid([any()], %Reconciliation.Event{}, %Graph{}) :: boolean()
  def is_valid(expectataions, trace_event, g) do
    case expectataions do
      %Validator.Recognizer{name: _name, map: map} ->
        Enum.map(map, fn {_k, x} -> is_valid(x, trace_event, g) end)
        |> Enum.all?()

      [] ->
        case length(Graph.out_neighbors(g, trace_event)) do
          0 -> true
          _ -> false
        end

      [head | tail] ->
        case head do
          %Validator.Notice{pattern: pattern} ->
            matching_events =
              Graph.out_neighbors(g, trace_event)
              |> Enum.filter(fn %Reconciliation.Event{
                                  detail: _detail,
                                  event_type: event_type,
                                  path_id: pathid
                                } ->
                event_type == :notice && String.match?(pathid, ~r/#{pattern}/)
              end)

            # At lease one of the route can match between expectation and trace
            if length(matching_events) > 0 do
              Enum.map(matching_events, fn e -> is_valid(tail, e, g) end)
              |> Enum.any?()
            else
              false
            end

          %Validator.Send{name: name} ->
            matching_events =
              Graph.out_neighbors(g, trace_event)
              |> Enum.filter(fn %Reconciliation.Event{
                                  detail: detail,
                                  event_type: event_type,
                                  path_id: _pathid
                                } ->
                event_type == :message && Map.fetch!(detail, "message_type") == "send" &&
                  String.match?(Map.fetch!(detail, "message_id"), ~r/#{name}/)
              end)

            if length(matching_events) > 0 do
              Enum.map(matching_events, fn e ->
                is_valid(tail, e, g)
              end)
              |> Enum.any?()
            else
              false
            end

          %Validator.Receive{name: name} ->
            matching_events =
              Graph.out_neighbors(g, trace_event)
              |> Enum.filter(fn %Reconciliation.Event{
                                  detail: detail,
                                  event_type: event_type,
                                  path_id: _pathid
                                } ->
                event_type == :message && Map.fetch!(detail, "message_type") == "receive" &&
                  String.match?(Map.fetch!(detail, "message_id"), ~r/#{name}/)
              end)

            if length(matching_events) > 0 do
              Enum.map(matching_events, fn e -> is_valid(tail, e, g) end)
              |> Enum.any?()
            else
              false
            end

          %Validator.Task{name: name, statements: statements} ->
            matching_events =
              Graph.out_neighbors(g, trace_event)
              |> Enum.filter(fn %Reconciliation.Event{
                                  detail: detail,
                                  event_type: event_type,
                                  path_id: _pathid
                                } ->
                event_type == :task && String.match?(Map.fetch!(detail, "name"), ~r/#{name}/)
              end)

            if length(matching_events) > 0 do
              tail = statements ++ tail

              Enum.map(matching_events, fn e -> is_valid(tail, e, g) end)
              |> Enum.any?()
            else
              false
            end

          %Validator.Repeat{low: low, high: high, statements: statements} ->
            case low do
              0 ->
                repeat_check(tail, statements, high - low, trace_event, g, [])
                |> Enum.any?()

              _ ->
                tail =
                  statements ++
                    [%Validator.Repeat{low: low - 1, high: high - 1, statements: statements}] ++
                    tail

                is_valid(tail, trace_event, g)
            end
        end
    end
  end

  @spec repeat_check([any()], [any()], non_neg_integer(), %Reconciliation.Event{}, %Graph{}, [
          boolean()
        ]) :: [boolean()]
  defp repeat_check(expectations, statements, count, trace_event, g, result) do
    case count do
      -1 ->
        result

      count ->
        new_expecs = (List.duplicate(statements, count) |> List.flatten()) ++ expectations
        result = result ++ [is_valid(new_expecs, trace_event, g)]
        repeat_check(expectations, statements, count - 1, trace_event, g, result)
    end
  end
end
