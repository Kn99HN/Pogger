defmodule AnalysisTest do
  use ExUnit.Case
  doctest Analysis

  test "basic_send_and_receive" do
    Analysis.basic_send_and_receive()
  end
end
