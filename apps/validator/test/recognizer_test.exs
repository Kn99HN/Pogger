defmodule RecognizerTest do
  use ExUnit.Case

  test "basic recognizer" do
    str1 = "
      validator(V) {
        process(A): {
          notice(A)
        }
      }
    "

    target1 = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Notice{
            pattern: "A"
          }
        ]
      }
    }

    res1 = Validator.to_recognizer(str1)

    assert res1 == target1
  end

  test "recognizer with nested statements" do
    str1 = "
      Validator(V) {
        process(A): {
          task(B): {
            notice(C);
          },
          task(C): {
            notice(D);
          }
        }
      }
    "

    target1 = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Task{
            name: "B",
            statements: [
              %Validator.Notice{
                pattern: "C"
              }
            ]
          },
          %Validator.Task{
            name: "C",
            statements: [
              %Validator.Notice{
                pattern: "D"
              }
            ]
          }
        ]
      }
    }

    res1 = Validator.to_recognizer(str1)

    assert res1 == target1
  end

  test "recognizer with multiple process" do
    str1 = "
      Validator(V) {
        process(A): {
          notice(B);
          notice(C);
        },
        process(B): {
          notice(C);
          notice(D);
        }
      }
    "

    target1 = %Validator.Recognizer{
      name: "V",
      map: %{
        "A" => [
          %Validator.Notice{
            pattern: "B"
          },
          %Validator.Notice{
            pattern: "C"
          }
        ],
        "B" => [
          %Validator.Notice{
            pattern: "C"
          },
          %Validator.Notice{
            pattern: "D"
          }
        ]
      }
    }

    res1 = Validator.to_recognizer(str1)

    assert res1 == target1
  end

  test "recognizer with send" do
    str1 = "
    Validator(A) {
      process(A) {
        send(a-enq);
      },
      process(B) {
        notice(b-deq),
        notice(b-receive),
        task(b-incr) {
          send(b-update);
        }
      }
    }"

    res1 = Validator.to_recognizer(str1)

    IO.puts("#{inspect(res1)}")
  end
end
