defmodule LuhnTest do
  use ExUnit.Case, aysnc: true

  test "non digit" do
    assert Luhn3.start_check("hello") == "hello"
  end

  test "<14 number test" do
    assert Luhn3.start_check("8393849384\n") == "8393849384\n"
  end

  test ">=14 number test" do
    assert Luhn3.start_check("56613959932537\n") == "XXXXXXXXXXXXXX\n"
  end

  test "number with spaces test" do
    assert Luhn3.start_check("56 6139 5993 2537\n") == "XX XXXX XXXX XXXX\n"
  end

  test "number with - test" do
    assert Luhn3.start_check("56-6139-5993-2537\n") == "XX-XXXX-XXXX-XXXX\n"
  end

  test "<16 number test" do
    assert Luhn3.start_check("83938493841234567\n") == "8XXXXXXXXXXXXXXX7\n"
  end

  test ">=14 and <=16 number test" do
    assert Luhn3.start_check("5612-6139-5993-2537\n") == "5612-6139-5993-2537\n"
  end

  test ">16 number test" do
    assert Luhn3.start_check("5612-6139-5993-25371\n") == "5612-6139-5993-25371\n"
  end
end
