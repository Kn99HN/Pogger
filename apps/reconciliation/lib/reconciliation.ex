defmodule Reconciliation do
  @moduledoc """
  This module will reconcile the trace file generated for each process
  to a global trace 
  """

  @spec combine_trace(String.t()) :: [%Reconciliation.Event{}]
  def combine_trace(file_path) do
    abs_path = Path.expand(file_path)
    case File.ls(abs_path) do
      {:ok, files} ->
        files
        |> Enum.filter(fn x -> !String.starts_with?(x, ".") end)
        |> Enum.flat_map(fn x -> parse_file(abs_path, x) end)

      {:error, reason} ->
        IO.puts("Unable to locate the trace files at #{inspect(file_path)} with error #{reason}")
    end
  end

  @spec parse_file(String.t(), String.t()) :: [%Reconciliation.Event{}]
  defp parse_file(file_path, file_name) do
    abs_path = Path.expand("#{file_path}/#{file_name}")
    case File.read(abs_path) do
      {:ok, f_content} ->
        case Jason.decode(f_content) do
          {:ok, file_content} ->
            create_trace_event(file_content)

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

  @spec create_trace_event(String.t()) :: [%Reconciliation.Event{}]
  defp create_trace_event(file_content) do
    path_id = Map.fetch!(file_content, "path_id")

    Map.fetch!(file_content, "events")
    |> Enum.map(fn x ->
      %Reconciliation.Event{
        path_id: path_id,
        event_type: check_event_type(x),
        detail: x
      }
    end)
  end

  @spec check_event_type(%Reconciliation.Event{}) :: :task | :message | :notice
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

  @spec make_vectors_equal_length(map(), map()) :: map()
  defp make_vectors_equal_length(v1, v2) do
    IO.puts("#{inspect(v1)} - #{inspect(v2)}")
    v1_add = for {k, _} <- v2, !Map.has_key?(v1, k), do: {k, 0}
    Map.merge(v1, Enum.into(v1_add, %{}))
  end

  @before :before
  @hafter :after
  @concurrent :concurrent

  @spec compare_component(non_neg_integer(), non_neg_integer()) :: :before | :after | :concurrent
  defp compare_component(c1, c2) do
    cond do
      c1 < c2 -> @before
      c1 > c2 -> @hafter
      true -> @concurrent
    end
  end

  @spec compare_vclock(%Reconciliation.Event{}, %Reconciliation.Event{}) ::
          :before | :after | :concurrent
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
      
      Enum.all?(compare_result, fn x -> x == @concurrent end) ->
        @concurrent
    end
  end

  @spec get_timestamp(%Reconciliation.Event{}) :: map()
  defp get_timestamp(event) do
    %Reconciliation.Event{
      path_id: _path_id,
      event_type: _event_type,
      detail: detail
    } = event

    detail
    |> Map.fetch!("timestamp")
    |> Map.fetch!("clock_value")
  end

  @spec trace_graph([%Reconciliation.Event{}]) :: %Graph{}
  def trace_graph(events) do
    # The graph has a dummy vertex linking to all the vertexes 
    Graph.new()
    |> add_str_vertex(events)
    |> update_vertices(events)
  end

  @spec add_str_vertex(%Graph{}, [%Reconciliation.Event{}]) :: %Graph{}
  def add_str_vertex(g, events) do
    dummy_start = Reconciliation.Event.start()

    g
    |> Graph.add_vertex(dummy_start)
    |> Reconciliation.add_str_edge(dummy_start, events)
  end

  @spec add_str_edge(%Graph{}, %Reconciliation.Event{}, [%Reconciliation.Event{}]) :: %Graph{}
  def add_str_edge(g, dummy_start, events) do
    case events do
      [] ->
        g

      [head | tail] ->
        g = g |> Graph.add_edge(Graph.Edge.new(dummy_start, head))
        add_str_edge(g, dummy_start, tail)
    end
  end

  @spec update_vertices(%Graph{}, [%Reconciliation.Event{}]) :: %Graph{}
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

  @spec update_edge(%Graph{}, %Reconciliation.Event{}, [%Reconciliation.Event{}]) :: %Graph{}
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
