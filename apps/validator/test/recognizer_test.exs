defmodule RecognizerTest do
  use ExUnit.Case

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

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
    res1 = Validator.parse_validator_to_recognizer(str1)


    assert res1 == target1
  end

  test "recognizer with nested" do
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
              },
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

    res1 = Validator.parse_validator_to_recognizer(str1)

    assert res1 == target1
  end
 end
