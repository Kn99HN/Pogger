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
            events = Map.fetch!(file_content, "events")

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

    if Enum.any?(compare_result, fn x -> x == @before end) do
      if Enum.any?(compare_result, fn x -> x == @hafter end) do
        @concurrent
      else
        @before
      end
    else
      if Enum.any?(compare_result, fn x -> x == @hafter end) do
        @hafter
      else
        @concurrent
      end
    end
  end

  defp get_timestamp(event) do
    clock_val =
      event
      |> Map.fetch!("timestamp")
      |> Map.fetch!("clock_value")
  end

  def trace_graph(events) do
    g =
      Graph.new()
      |> update_vertices(events)
  end

  def update_vertices(g, events) do
    if events == [] do
      g
    else
      [head | tail] = events

      g =
        g
        |> Graph.add_vertex(head)
        |> Reconciliation.update_edge(head, tail)

      update_vertices(g, tail)
    end
  end

  def update_edge(g, event, events) do
    if events == [] do
      g
    else
      [head | tail] = events

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
