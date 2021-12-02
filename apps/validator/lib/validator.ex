defmodule Validator do
  defp get_pattern_from_expectation(s) do
    Regex.run(~r/\((.*?]*)\)/, s) |> Enum.at(1)
  end

  defp parse_notice(s) do
    %Validator.Notice{
      pattern: get_pattern_from_expectation(s)
    }
  end

  defp parse_send(s) do
    %Validator.Send{
      name: get_pattern_from_expectation(s)
    }
  end

  defp parse_receive(s) do
    %Validator.Receive{
      name: get_pattern_from_expectation(s)
    }
  end

  defp parse_task(s) do
    %Validator.Task{
      name: get_pattern_from_expectation(s)
    }
  end

  defp parse_maybe(s) do
    if s == "maybe" do
      %Validator.Repeat{
        low: 0,
        high: 1
      }
    end
  end

  defp parse_repeat(tokens) do
    %Validator.Repeat{
      low: String.to_integer(Enum.at(tokens, 1)),
      high: String.to_integer(Enum.at(tokens, 2))
    }
  end

  defp parse_recognizer(s) do
    %Validator.Recognizer{
      name: get_pattern_from_expectation(s)
    }
  end

  defp find_indexes(tokens, index, ls) do
    if index >= length(tokens) do
      nil
    else
      curr = Enum.at(tokens, index)
      {char, idx} = Enum.at(ls, 0, {"", 0})

      cond do
        curr == "}" and char == "{" ->
          case Enum.slice(ls, 1..length(ls)) do
            [] -> {idx, index}
            inner_ls -> find_indexes(tokens, index + 1, inner_ls)
          end

        curr == "{" ->
          find_indexes(tokens, index + 1, [{curr, index}] ++ ls)

        true ->
          find_indexes(tokens, index + 1, ls)
      end
    end
  end

  @doc """
  Parse recognizer from list of tokens. Tokens have the 
  form ["process(A)", "{", "{", "notice(A)", "}", "}"].
  The output of the recorgnizer: {
    recognizer: {
      map: {
        process_name => [{expectation}]
      }
    }
  }
  """
  @spec parse_recognizer([any()], %Validator.Recognizer{}) :: %Validator.Recognizer{}
  defp parse_recognizer(tokens, recognizer) do
    case tokens do
      [] ->
        recognizer

      tokens ->
        case find_indexes(tokens, 0, []) do
          {low, high} ->
            process_str = Enum.at(tokens, 0)
            process_name = get_pattern_from_expectation(process_str)
            process_expectations_str = Enum.slice(tokens, (low + 1)..(high - 1))
            process_expectations = parse_tokens(process_expectations_str, [])

            recognizer = %{
              recognizer
              | map: Map.put(recognizer.map, process_name, process_expectations)
            }

            parse_recognizer(Enum.slice(tokens, (high + 1)..length(tokens)), recognizer)

          nil ->
            recognizer
        end
    end
  end

  @doc """
  Parsing tokens into list of expectation statements.
  1. Find index of nested statements
  2. Parse nested statements recursively
  3. If not indexes are found then we are at the lowest level
  """
  @spec parse_tokens([any()], [any()]) :: [any()]
  defp parse_tokens(tokens, expectations) do
    case find_indexes(tokens, 0, []) do
      {low, high} ->
        case tokens do
          [head | tail] ->
            new_tokens = Enum.slice(tokens, (low + 1)..(high - 1))
            other_tokens = Enum.slice(tokens, (high + 1)..length(tokens))

            cond do
              String.starts_with?(head, "task") ->
                task = parse_task(head)
                task = %{task | statements: parse_tokens(new_tokens, expectations)}
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

              true ->
                expectations
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
              
              String.starts_with?(head, "task") ->
                task = parse_task(head)
                [task] ++ parse_tokens(tail, expectations)

            end

          [] ->
            expectations
        end
    end
  end

  @doc """
  Tokenizing input string by filtering out extra character.
  """
  @spec tokenize([String.t()], non_neg_integer(), [String.t()]) :: [String.t()]
  defp tokenize(strs, index, tokens) do
    if index >= length(strs) do
      tokens
    else
      line = Enum.at(strs, index)

      lines =
        String.split(line, " ")
        |> Enum.map(fn s -> String.replace(s, [":", ",", ";"], "") end)
        |> Enum.filter(fn s ->
          s != nil and s != " " and s != "" and s != "between" and s != "and"
        end)

      tokenize(strs, index + 1, tokens ++ lines)
    end
  end

  @doc """
  Split by whitespace and filter out whitespace characters
  """
  @spec prepare_validator(String.t()) :: [String.t()]
  defp prepare_validator(s) do
    String.split(s, "\n")
    |> Enum.map(fn str -> String.trim(str) end)
    |> Enum.filter(fn s -> s != "" end)
  end

  @doc """
  Parse validator from input string
  """
  @spec to_validator(String.t()) :: [any()]
  def to_validator(s) do
    strs = prepare_validator(s)
    tokens = tokenize(strs, 0, [])
    parse_tokens(tokens, [])
  end

  @doc """
  Parse recognizer from input string
  """
  @spec to_recognizer(String.t()) :: %Validator.Recognizer{}
  def to_recognizer(s) do
    strs = prepare_validator(s)
    validator = Enum.at(strs, 0)
    tokens = tokenize(Enum.slice(strs, 1..(length(strs) - 2)), 0, [])
    recognizer = parse_recognizer(validator)
    parse_recognizer(tokens, recognizer)
  end

  defp get_file_path do
    System.get_env("EXPECTATION_FILE")
  end
end
