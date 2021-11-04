defmodule RecognizerTest do
  use ExUnit.Case

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

  test "basic validator" do
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

 end
