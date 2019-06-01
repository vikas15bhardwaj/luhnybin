defmodule Luhn5 do
  def main(_args) do
    read_line()
  end

  def read_line() do
    case IO.read(:stdio, :line) do
      "\n" ->
        :ok

      line ->
        IO.write(check(line))
        read_line()
    end
  end

  def check(line) do
    line_chars = to_charlist(line)

    result = luhn_check(line_chars, "", [])
    # IO.puts("result #{result}")

    if !String.contains?(result, "X"),
      do: check(line_chars, ""),
      else: result
  end

  def check([line_head | line_tail], result) when line_tail != [] do
    check_result = luhn_check(line_tail, "", [])

    if !String.contains?(check_result, "X"),
      do: check(line_tail, result <> List.to_string([line_head])),
      else: result <> List.to_string([line_head]) <> check_result
  end

  def check([line_head | line_tail], result) when line_tail == [] do
    result <> List.to_string([line_head])
  end

  def luhn_check([text_to_check | tail], result, card) when is_binary(result) do
    # return the entire string either with same card number or replaced with masked if a valid card number
    # IO.puts("luhncheck #{inspect(card)}")
    card_length = Enum.count(card, fn x -> x != 32 && x != 45 end) + 1
    # IO.puts("result #{result}")
    # IO.puts(inspect(tail))

    # validate each 16 length or 14 and 15 length string to check if its a valid card number
    # if its 16 length or  if its the last remaining 14 or 15 lenght card and it would never reach to 16
    if card_length >= 16 ||
         (card_length >= 14 && card_length < 16 && tail == []) do
      luhn_check(
        tail,
        String.replace(
          result <> List.to_string([text_to_check]),
          String.reverse(List.to_string([text_to_check | card])),
          validate_and_mask([text_to_check | card], card_length)
        ),
        []
      )
    else
      luhn_check(tail, result <> List.to_string([text_to_check]), [text_to_check | card])
    end

    # end
  end

  def luhn_check([], result, card) do
    # IO.puts("card #{String.reverse(to_string(card))}")
    card_without_n = Enum.reject(card, fn x -> x == 10 end)
    # IO.puts(inspect(card_without_n))
    card_in_right_order = String.reverse(to_string(card_without_n))
    card_digits = to_charlist(card_in_right_order)
    # IO.puts(inspect(card_digits))

    if String.length(result) > 16 &&
         Enum.count(card_digits, fn x -> x == 48 end) == Enum.count(card_digits) do
      String.replace(result, card_in_right_order, mask(card_digits, []))
    else
      result
    end
  end

  defp validate_and_mask(card, card_length) do
    # IO.puts(card)
    masked = validate_and_mask(card, "", [], card_length)
    # IO.puts("masked: #{masked}")
    masked
  end

  # build the card_digits with integers and then validate
  defp validate_and_mask([card_head | card_tail], result, card_digits, card_length) do
    # if integer then add to card_digits
    # IO.puts("validate_and_mask[card_head|card_tail] #{inspect(card_digits)}")

    # IO.puts(card_length)

    cond do
      (card_head >= 48 && card_head <= 57) || card_head == 32 || card_head == 45 ->
        card_length = Enum.count(card_digits, fn x -> x != 32 && x != 45 end) + 1

        validate_and_mask(
          card_tail,
          result <> List.to_string([card_head]),
          [card_head | card_digits],
          card_length
        )

      # card_head == 32 || card_head == 45 ->
      #   # continue to build card digits if we hit space or hyphen
      #   validate_and_mask(tail, result <> List.to_string(card_head), card_digits)

      # if we hit with a non integer at the end but we have enough digits to validate
      card_length >= 14 ->
        card_length = Enum.count(card_digits, fn x -> x != 32 && x != 45 end)

        validate_and_mask(
          card_tail,
          result <> List.to_string([card_head]),
          card_digits,
          card_length
        )

      true ->
        # reset the card digits as soon as we hit a non integer
        validate_and_mask(card_tail, result <> List.to_string([card_head]), [], card_length)
    end
  end

  defp validate_and_mask([], result, card_digits, card_length) when card_length >= 14 do
    # IO.puts("validate_and_mask[] #{inspect(card_digits)}")
    # Enum.reverse(card_digits)

    card_digits_in_right_order = card_digits
    [val, skip_digits] = validate(card_digits_in_right_order, [], card_length)

    if val,
      do:
        String.replace(
          String.reverse(result),
          List.to_string(card_digits_in_right_order),
          mask(card_digits_in_right_order, skip_digits)
        ),
      else: String.reverse(result)
  end

  defp validate_and_mask([], result, card_digits, card_length) when card_length < 14 do
    # IO.puts("validatea_and_mask4")
    String.reverse(result)
  end

  defp validate(card_digits, skipped_digits, card_length) when card_length < 14 do
    # IO.puts("validate < 14")
    [false, []]
  end

  # validate the card number, at this point it only has integers >=14
  defp validate(card_digits, skipped_digits, card_length) when card_length >= 14 do
    # IO.puts(inspect(card_digits))

    [val, _] = validate(card_digits, card_length)

    # IO.puts(val)

    if(val || card_length < 14) do
      [val, skipped_digits]
    else
      [val, sd] = validate(tl(card_digits), [hd(card_digits) | skipped_digits], card_length - 1)

      [val2, sd2] =
        validate(
          Enum.slice(card_digits, 0, length(card_digits) - 1),
          [-List.last(card_digits) | skipped_digits],
          card_length - 1
        )

      cond do
        val == true -> [val, sd]
        val2 == true -> [val2, sd2]
        true -> [false, []]
      end
    end
  end

  defp validate(card_digits, card_length) when card_length >= 14 do
    IO.puts("validate #{inspect(card_digits)}")
    # skip the last digit

    card_number = card_digits |> Enum.filter(&(&1 != 32 && &1 != 45))

    cond do
      length(card_number) > 16 ->
        [false, []]

      rem(length(card_number), 2) == 0 ->
        every_second_double =
          card_number
          |> Enum.with_index()
          |> Enum.map(fn {x, i} ->
            if rem(i, 2) == 0 && i < Enum.count(card_number) - 1,
              do: List.to_integer([x]) * 2,
              else: List.to_integer([x])
          end)
          |> Enum.flat_map(fn x -> String.split(to_string(x), "", trim: true) end)
          |> Enum.map(fn x -> String.to_integer(x) end)

        # IO.puts("sum #{Enum.sum(every_second_double)}")
        [Integer.mod(Enum.sum(every_second_double), 10) == 0, []]

      true ->
        every_second_double =
          card_number
          |> Enum.with_index()
          |> Enum.map(fn {x, i} ->
            if rem(i, 2) != 0 && i < Enum.count(card_number) - 1,
              do: List.to_integer([x]) * 2,
              else: List.to_integer([x])
          end)
          |> Enum.flat_map(fn x -> String.split(to_string(x), "", trim: true) end)
          |> Enum.map(fn x -> String.to_integer(x) end)

        # IO.puts(inspect(every_second_double))

        [Integer.mod(Enum.sum(every_second_double), 10) == 0, []]
    end
  end

  defp validate(card_digits, _card_length) do
    [false, []]
  end

  defp mask(card_number, skip_digits) do
    left_skip = Enum.filter(skip_digits, &(&1 >= 0))
    right_skip = Enum.filter(skip_digits, &(&1 < 0))

    mask(card_number, left_skip, right_skip)
  end

  defp mask(card_number, left_skip, right_skip) do
    # IO.puts(right_skip)
    # masked = String.split(card_number,"",trim: true)
    #           |> Enum.drop(Enum.count(left_skip)) |> Enum.drop(-(Enum.count(right_skip)))
    #           |> Enum.map_join(fn x-> if !Regex.match?(~r{ |-|\n|\\n}, x), do: "X", else: x end)
    masked =
      card_number
      |> Enum.drop(Enum.count(left_skip))
      |> Enum.drop(-Enum.count(right_skip))
      |> Enum.map_join(fn x ->
        if !Regex.match?(~r{ |-}, to_string([x])), do: "X", else: List.to_string([x])
      end)

    # left = left_skip |> Enum.reverse() |> Enum.join()
    left = left_skip |> Enum.reverse() |> List.to_string()
    right = right_skip |> Enum.map(fn x -> -x end) |> List.to_string()

    masked = left <> masked <> right
    # IO.puts(masked)
    masked
  end
end
