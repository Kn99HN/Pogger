defmodule Reconciliation do
  @moduledoc """
  This module will reconcile the trace file generated for each process
  to a global trace 
  """

  import Emulation

  def combine_trace(file_path) do
    case File.ls(file_path) do
      {:ok, files} ->
        files
        |> Enum.filter(fn x -> !String.starts_with?(x, ".") end)
        |> Enum.flat_map(fn x -> parse_file(file_path, x) end)

      {:error, reason} ->
        IO.puts("Unable to locate the trace files with error #{reason}")
    end
  end

  defp parse_file(file_path, file_name) do
    case File.read("#{file_path}/#{file_name}") do
      {:ok, f_content} ->
        case Jason.decode(f_content) do
          {:ok, file_content} ->
            events = create_trace_event(file_content)

          {:error, _} ->
            IO.puts("Unexpected trace file format, unable to decode to Json")
        end

      {:error, _} ->
        IO.puts("Unable to read the trace file content")
    end
  end

  def get_file_path() do
    System.get_env("TRACE_FILES")
  end

  defp create_trace_event(file_content) do
    path_id = Map.fetch!(file_content, "path_id")

    events =
      Map.fetch!(file_content, "events")
      |> Enum.map(fn x ->
        %Reconciliation.Event{
          path_id: path_id,
          event_type: check_event_type(x),
          detail: x
        }
      end)
  end

  defp check_event_type(event) do
    if Map.has_key?(event, "ttype") do
      :task
    else
      if Map.has_key?(event, "message_type") do
        :message
      else
        :notice
      end
    end
  end

  defp make_vectors_equal_length(v1, v2) do
    v1_add = for {k, _} <- v2, !Map.has_key?(v1, k), do: {k, 0}
    Map.merge(v1, Enum.into(v1_add, %{}))
  end

  @before :before
  @hafter :after
  @concurrent :concurrent

  defp compare_component(c1, c2) do
    cond do
      c1 < c2 -> @before
      c1 > c2 -> @hafter
      true -> @concurrent
    end
  end

  def compare_vclock(event1, event2) do
    v1 = get_timestamp(event1)
    v2 = get_timestamp(event2)

    v1 = make_vectors_equal_length(v1, v2)
    v2 = make_vectors_equal_length(v2, v1)

    compare_result = Map.values(Map.merge(v1, v2, fn _k, c1, c2 -> compare_component(c1, c2) end))

    cond do
      Enum.any?(compare_result, fn x -> x == @before end) &&
          Enum.any?(compare_result, fn x -> x == @hafter end) ->
        @concurrent

      Enum.any?(compare_result, fn x -> x == @before end) ->
        @before

      Enum.any?(compare_result, fn x -> x == @hafter end) ->
        @hafter
    end
  end

  defp get_timestamp(event) do
    %Reconciliation.Event{
      path_id: path_id,
      event_type: event_type,
      detail: detail
    } = event

    detail
    |> Map.fetch!("timestamp")
    |> Map.fetch!("clock_value")
  end

  def trace_graph(events) do
    # The graph has a dummy vertex linking to all the vertexes 
    Graph.new()
    |> add_str_vertex(events)
    |> update_vertices(events)
  end

  def add_str_vertex(g, events) do
    dummy_start = Reconciliation.Event.start()

    g =
      g
      |> Graph.add_vertex(dummy_start)
      |> Reconciliation.add_str_edge(dummy_start, events)
  end

  def add_str_edge(g, dummy_start, events) do
    case events do
      [] ->
        g

      [head | tail] ->
        g = g |> Graph.add_edge(Graph.Edge.new(dummy_start, head))
        add_str_edge(g, dummy_start, tail)
    end
  end

  def update_vertices(g, events) do
    case events do
      [] ->
        g

      [head | tail] ->
        g =
          g
          |> Graph.add_vertex(head)
          |> Reconciliation.update_edge(head, tail)

        update_vertices(g, tail)
    end
  end

  def update_edge(g, event, events) do
    case events do
      [] ->
        g

      [head | tail] ->
        case compare_vclock(event, head) do
          @before ->
            g = g |> Graph.add_edge(Graph.Edge.new(event, head))
            update_edge(g, event, tail)

          @hafter ->
            g = g |> Graph.add_edge(Graph.Edge.new(head, event))
            update_edge(g, event, tail)

          @concurrent ->
            update_edge(g, event, tail)
        end
    end
  end
end
