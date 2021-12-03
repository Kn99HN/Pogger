defmodule AnalysisTest do
  use ExUnit.Case
  doctest Analysis

  @tag disabled: true
  test "basic_send_and_receive" do
    Analysis.basic_send_and_receive()
  end

  @tag disabled: true
  test "nonsequentail_send_and_receive" do
    Analysis.nonsequentail_send_and_receive()
  end
end
