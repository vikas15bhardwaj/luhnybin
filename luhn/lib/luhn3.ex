defmodule Luhn3 do

  def main(_args) do
    read_line()
  end

  def read_line() do
    case IO.read(:stdio, :line) do
      "\n" -> :ok
      line ->
        IO.write(start_check(line))
        read_line()
    end
  end


  def start_check(card_number) do
      {:ok, file} = File.open("log.txt", [:append])
      IO.binwrite(file, card_number)
      IO.binwrite(file, "\r")
      File.close(file)

      card_list = String.split(card_number, "", trim: true)
      |> Enum.reduce("", fn x,acc -> if Integer.parse(x) != :error || x == " " || x == "-" || x == "\n", do: acc <> x, else: acc<> "A"  end)
      |> String.split(~r{[A-Z]}, trim: true)
      |> Enum.map(&(String.trim(&1)))
      |> Enum.filter(&(&1 != ""))

      #IO.puts inspect card_list
      if card_list == [] do
        card_number
      else
        Enum.reduce(card_list, "",fn x,acc -> if acc == "", do: acc = String.replace(card_number, x, check(x)), else: acc = String.replace(acc, x, check(x)) end)
      end

  end

  #32 - space
  #45 - hyphen
  #10 - \n
  #48-57 - [0-9]
  def check(card_number) do
    card_number2 = String.replace(card_number, ~r{ |-|\n|\\n}, "")

    if String.length(card_number2) >= 14 do

      card_digits = String.split(card_number2,"",trim: true) |> Enum.split(16) |> Tuple.to_list()
        #split card into numbers list
        # card_digits =  Enum.map(String.split(card_number2,"",trim: true), fn x-> String.to_integer(x) end)
        #               |> Enum.split(16) |> Tuple.to_list()

        # Enum.reduce(card_digits, "", fn x,acc ->
        #   case validate(x,[]) do
        #     [true,_,skip_digits] -> acc <> mask(x, skip_digits)
        #     [false,_,_] -> acc <> Enum.map_join(x, fn f -> to_string(f) end)
        #   end
        # end)
        #if val, do: mask(card_number, skip_mask, card_digits)

        validate(card_digits, "")
      else
        card_number
      end
  end

  defp validate([card_digits | tail], acc) when is_binary(acc) do
    case validate(card_digits,[]) do
      [true,_,skip_digits] -> acc <> mask(card_digits, skip_digits) <> validate(tail, acc)
      [false,_,_] -> acc <> Enum.map_join(card_digits, fn f -> to_string(f) end) <> validate(tail, acc)
    end
  end

  defp validate([], acc) when is_binary(acc) do
    acc
  end

  defp validate(card_digits, skip_digits) do
    #IO.puts inspect card_digits
    [val, _, _] = validate(card_digits)

    if(val || length(card_digits) < 14) do
      [val, card_digits, skip_digits]
    else
      [val, cd, sd] = validate(tl(card_digits), [hd(card_digits) | skip_digits])
      [val2, cd2, sd2] = validate(Enum.slice(card_digits, 0, length(card_digits) -1), [-List.last(card_digits) | skip_digits])
      cond do
        val == true -> [val, cd, sd]
        val2 == true -> [val2, cd2, sd2]
        true -> [false, card_digits, []]
      end
    end
  end

  defp validate(card_digits) when length(card_digits) >= 14 do
    #IO.puts inspect card_digits
    #skip the last digit

    cond do
      length(card_digits) > 16 ->
        [false, card_digits, []]

      rem(length(card_digits),2) == 0 ->
        every_second_double = Enum.with_index(card_digits)
                            |> Enum.map(fn {x, i} -> if rem(i, 2) == 0 && i < Enum.count(card_digits)-1, do: x * 2, else: x end)
                            |> Enum.flat_map(fn x -> String.split(to_string(x), "", trim: true) end)
                            |> Enum.map(fn x -> String.to_integer(x) end)
        [Integer.mod(Enum.sum(every_second_double), 10) == 0, card_digits, []]
      true ->
        every_second_double = Enum.with_index(card_digits)
                            |> Enum.map(fn {x, i} -> if rem(i, 2) != 0 && i < Enum.count(card_digits)-1, do: x * 2, else: x end)
                            |> Enum.flat_map(fn x -> String.split(to_string(x), "", trim: true) end)
                            |> Enum.map(fn x -> String.to_integer(x) end)

        [Integer.mod(Enum.sum(every_second_double), 10) == 0, card_digits, []]
    end
  end

  defp validate(card_digits) do
    [false,card_digits,[]]
  end

  defp mask(card_number, skip_digits) do
    left_skip = Enum.filter(skip_digits, &(&1 >= 0))
    right_skip = Enum.filter(skip_digits, &(&1 < 0))

    mask(card_number, left_skip, right_skip)
  end

  defp mask(card_number, left_skip, right_skip) do

    # masked = String.split(card_number,"",trim: true)
    #           |> Enum.drop(Enum.count(left_skip)) |> Enum.drop(-(Enum.count(right_skip)))
    #           |> Enum.map_join(fn x-> if !Regex.match?(~r{ |-|\n|\\n}, x), do: "X", else: x end)

    #IO.puts inspect card_number
    masked = card_number
              |> Enum.drop(Enum.count(left_skip)) |> Enum.drop(-(Enum.count(right_skip)))
              |> Enum.map_join(fn x-> if !Regex.match?(~r{ |-|\n|\\n}, to_string(x)), do: "X", else: to_string(x) end)

    left = left_skip |> Enum.reverse() |> Enum.join()
    right = right_skip |> Enum.map(fn x-> -x end) |> Enum.join()

    left <> masked <> right

  end

end
