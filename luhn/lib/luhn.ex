defmodule Luhn do

  require Logger

  def test do
    {true, "test", "abc"}
  end
  def main(_args) do
    read_line()
  end

  def read_line() do
    case IO.read(:stdio, :line) do
      "\n" -> :ok
      line ->
        IO.write(check(line))
        read_line()
    end
    #Enum.each(IO.stream(:stdio, :line), &IO.write(check(&1)))
  end

  def check(card_number) when is_integer(card_number) do
    check(to_string(card_number))
  end

  def check(card_number) do

    card_number2 = String.replace(card_number, ~r{ |-|\n|\\n}, "")

    #IO.write("#{card_number}")
    if String.length(card_number2) >= 14 && String.length(card_number2) <= 16
      && Regex.match?(~r{\d},card_number2) do
      {val, slicedCardLength} = validate(card_number2)
      IO.puts inspect {val, slicedCardLength}

      #IO.puts sliced
      n = String.length(card_number2) - slicedCardLength

      IO.puts n
      if val do
        slicedCard = Enum.take(String.split(card_number,"",trim: true),  -(String.length(card_number) - n))
        IO.puts(inspect slicedCard)
        masked = Enum.map_join(slicedCard, fn x-> if !Regex.match?(~r{ |-|\n|\\n}, x) , do: "X", else: x end)
        IO.puts(masked)

        not_masked = String.slice(card_number, 0, n)
        IO.puts not_masked
        not_masked <> masked
      else
        card_number
      end
    else
      card_number
    end
  end

  defp validate(card_number) do

    IO.puts "validate #{card_number}"
    n = String.length(card_number) - 14
    IO.puts "n #{n}"

    #Logger.info(card_number)
    card_digits = Enum.map(String.split(String.reverse(card_number),"",trim: true), fn x-> String.to_integer(x) end)


    every_second_double = Enum.map(Enum.with_index(card_digits), fn {x, i} -> if Integer.mod(i, 2) != 0, do: x * 2, else: x end)
    #Logger.info(inspect every_second_double)

    #if product is a double digit split it into single digit
    individual_double_digits =
      Enum.flat_map(every_second_double, fn x -> String.split(to_string(x), "", trim: true) end)

    individual_double_digits =
        Enum.map(individual_double_digits, fn x -> String.to_integer(x) end)

    #Logger.info(inspect individual_double_digits)
    #Logger.info(Enum.sum(individual_double_digits))
    val = Integer.mod(Enum.sum(individual_double_digits), 10) == 0

    #if whole card is not a valid card, then check if 15 or 14 digit card is valid from left and right
    if(!val && n > 0) do
      #take from left
      IO.puts "left"
      val = validate(String.slice(card_number, 1, String.length(card_number)))
      IO.puts "left done #{inspect val}"
      if (val) do
        {val, String.length(card_number)}
      end
    else
      {val, String.length(card_number)}
    end




  end

end
