defmodule Validator do
  
  def get_pattern_from_expectation(s) do
    Regex.run(~r/\((.*?]*)\)/, s) |> Enum.at(1)
  end

  def parse_notice(s) do
    notice_pattern = get_pattern_from_expectation(s)
    %Validator.Notice{
      pattern: notice_pattern
    }
  end

  def parse_send(s) do
    sent_process = get_pattern_from_expectation(s)
    %Validator.Send{
      pname: sent_process,
    }
  end

  def parse_receive(s) do
    received_process = get_pattern_from_expectation(s)
    %Validator.Receive{
      pname: received_process
    }
  end

  def parse_task(s) do
    task_name = get_pattern_from_expectation(s)
    %Validator.Task{
      tname: task_name
    }
  end

  def parse_maybe(s) do
    if s == "maybe" do
      %Validator.Repeat{
        low: 0,
        high: 1,
      }
    end
  end

  def parse_repeat(tokens) do
    %Validator.Repeat{
      low: String.to_integer(Enum.at(tokens, 1)),
      high: String.to_integer(Enum.at(tokens, 2))
    }
  end

  def is_statment(s) do
    String.starts_with?(s, ["task", "maybe", "repeat"])
  end

  defp find_indexes(tokens, index, ls) do
    if index >= length(tokens) do
      nil
    else
      curr = Enum.at(tokens, index)
      {char, idx} = Enum.at(ls, 0, {"", 0})
      cond do
        curr == "}" and char == "{"  ->
          if Enum.slice(ls, 1..length(ls)) == [] do
            {idx, index}
          else
            find_indexes(tokens, index + 1, Enum.slice(ls, 1..length(ls)))
          end
        curr == "{" ->
          find_indexes(tokens, index + 1, [{curr, index}] ++ ls)
        true ->
          find_indexes(tokens, index + 1, ls)
      end
    end
  end

  defp parse_tokens(tokens, expectations) do
    case find_indexes(tokens, 0, []) do
      {low, high} ->
       case tokens do
        [head | tail] ->
           new_tokens = Enum.slice(tokens, low + 1..high - 1)
           other_tokens = Enum.slice(tokens, high + 1..length(tokens))
           cond do
              String.starts_with?(head, "task") ->
                task = parse_task(head)
                task = %{task | subtasks: parse_tokens(new_tokens, expectations)}
                [task] ++ parse_tokens(other_tokens, expectations)
              String.starts_with?(head, "maybe") ->
                maybe = parse_maybe(head)
                maybe = %{maybe | statements: parse_tokens(new_tokens, expectations)}
                [maybe] ++ parse_tokens(other_tokens, expectations)
              String.starts_with?(head, "repeat") ->
                repeat_stmt = parse_repeat(tokens)
                repeat_stmt = %{repeat_stmt | statements: parse_tokens(new_tokens, expectations)}
                [repeat_stmt] ++ parse_tokens(other_tokens, expectations)
              String.starts_with?(head, "notice") ->
                notice = parse_notice(head)
                [notice] ++ parse_tokens(tail, expectations)
              String.starts_with?(head, "send") ->
                send = parse_send(head)
                [send] ++ parse_tokens(tail, expectations)
              String.starts_with?(head, "receive") ->
                receive = parse_receive(head)
                [receive] ++ parse_tokens(tail, expectations)
              true -> expectations
           end
         [] ->
          expectations
      end
       nil ->
        case tokens do
          [head | tail] ->
            cond do
              String.starts_with?(head, "notice") ->
                notice = parse_notice(head)
                [notice] ++ parse_tokens(tail, expectations)
              String.starts_with?(head, "send") ->
                send = parse_send(head)
                [send] ++ parse_tokens(tail, expectations)
              String.starts_with?(head, "receive") ->
                receive = parse_receive(head)
                [receive] ++ parse_tokens(tail, expectations)
            end
          [] -> expectations
        end
    end
  end


  defp tokenizer(strs, index, tokens) do
    if index >= length(strs) do
      tokens
    else
      line = Enum.at(strs, index)
      lines = String.split(line, " ")
        |> Enum.map(fn s -> String.replace(s, ":", "") end)
        |> Enum.map(fn s -> String.replace(s, ";", "") end)
        |> Enum.filter(fn s -> s != nil and s != " " and s != "" and s != "between" and s != "and" end)
      tokenizer(strs, index + 1, tokens ++ lines)
    end
  end

  def parse_validator(s) do
    strs = String.split(s, "\n") |> Enum.map(fn str -> String.trim(str) end) |> Enum.filter(fn s -> s != "" end)
    tokens = tokenizer(strs, 0, [])
    validator = Enum.at(strs, 0)
    parsed_validator = parse_tokens(tokens, [])
    parsed_validator
  end
  
  defp get_file_path do
    System.get_env("EXPECTATION_FILE")
  end
end
