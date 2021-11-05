defmodule ValidatorTest do
  use ExUnit.Case

  test "Test validator with nested task and maybe statements" do
    str1 = "
      task(A) {
        maybe {
          notice(B);
        }
        task(A2) {
            notice(D)
        }
      }"

    target1 = %Validator.Task{
      name: "A",
      statements: [
        %Validator.Repeat{
          low: 0,
          high: 1,
          statements: [%Validator.Notice{pattern: "B"}]
        },
        %Validator.Task{
          name: "A2",
          statements: [%Validator.Notice{pattern: "D"}]
        }
      ]
    }

    res = Validator.to_validator(str1)
    assert res == [target1]

    str2 = "
      task(A) {
        maybe {
          notice(B);
          notice(C);
          task(D) {
            notice(E)
          }
        }
      }
    "

    target2 = %Validator.Task{
      name: "A",
      statements: [
        %Validator.Repeat{
          low: 0,
          high: 1,
          statements: [
            %Validator.Notice{
              pattern: "B"
            },
            %Validator.Notice{
              pattern: "C"
            },
            %Validator.Task{
              name: "D",
              statements: [
                %Validator.Notice{
                  pattern: "E"
                }
              ]
            }
          ]
        }
      ]
    }

    res2 = Validator.to_validator(str2)
    assert res2 == [target2]

    str3 = "
      task(A) {
        notice(B);
      }
      task(C) {
        notice(D);
      }
    "

    target3 = [
      %Validator.Task{
        name: "A",
        statements: [
          %Validator.Notice{
            pattern: "B"
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

    res3 = Validator.to_validator(str3)
    assert res3 == target3
  end

  test "basic validator" do
    str1 = "
      notice(A)
    "

    target1 = %Validator.Notice{
      pattern: "A"
    }

    res1 = Validator.to_validator(str1)

    str2 = "
      send(A)
    "

    target2 = %Validator.Send{
      name: "A"
    }

    res2 = Validator.to_validator(str2)

    str3 = "
      receive(A)
    "

    target3 = %Validator.Receive{
      name: "A"
    }

    res3 = Validator.to_validator(str3)

    assert res1 == [target1]
    assert res2 == [target2]
    assert res3 == [target3]
  end

  test "validator with repeat" do
    str1 = "
      repeat between 1 and 10 {
        notice(A);
        notice(B);
      }
    "

    target1 = %Validator.Repeat{
      low: 1,
      high: 10,
      statements: [
        %Validator.Notice{
          pattern: "A"
        },
        %Validator.Notice{
          pattern: "B"
        }
      ]
    }

    res1 = Validator.to_validator(str1)

    assert res1 == [target1]
  end

  test "validator with maybe" do
    str1 = "
      maybe {
        notice(A);
        notice(B);
      }
    "

    target1 = %Validator.Repeat{
      low: 0,
      high: 1,
      statements: [%Validator.Notice{pattern: "A"}, %Validator.Notice{pattern: "B"}]
    }

    res1 = Validator.to_validator(str1)

    assert res1 == [target1]
  end
end
