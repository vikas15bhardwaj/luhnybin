defmodule Luhn4 do
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

  def luhn_check([text_to_check | tail], result, card, prev_card \\ [], card_length \\ 1)
      when is_binary(result) do
    card = [text_to_check | card]

    # return the entire string either with same card number or replaced with masked if a valid card number
    # validate each 16 length or 14 and 15 length string to check if its a valid card number
    # if its 16 length or  if its the last remaining 14 or 15 lenght card and it would never reach to 16

    cond do
      card_length >= 16 || (card_length >= 14 && card_length < 16 && tail == [10]) ->
        luhn_check(
          tail,
          String.replace(
            result <> List.to_string([text_to_check]),
            String.reverse(List.to_string(card)),
            validate_and_mask(card, card_length)
          ),
          [],
          card
        )

      (text_to_check >= 48 && text_to_check <= 57) ||
        text_to_check == 32 || text_to_check == 45 ->
        card_length = Enum.count(card, fn x -> x != 32 && x != 45 end) + 1

        luhn_check(
          tail,
          result <> List.to_string([text_to_check]),
          card,
          prev_card,
          card_length
        )

      tail == [] && card_length > 1 ->
        luhn_check(tail, result <> List.to_string([text_to_check]), card, prev_card)

      true ->
        # reset the card digits as soon as we hit a non integer
        luhn_check(tail, result <> List.to_string([text_to_check]), [], prev_card)
    end
  end

  def luhn_check([], result, card, prev_card, card_length) do
    card_without_n = Enum.reject(card, fn x -> x == 10 end)

    if String.length(result) > 16 && card_without_n != [] do
      card_in_right_order = String.reverse(to_string(card_without_n))
      overlap_digits = prev_card |> Enum.take(16 - length(card_without_n)) |> Enum.reverse()

      card = to_charlist(to_string([overlap_digits | card_in_right_order]))

      mask = validate_and_mask(Enum.reverse(card), length(card))

      if String.ends_with?(mask, "X") do
        result =
          String.replace(result, card_in_right_order, mask(to_charlist(card_in_right_order), []))

        result
      else
        result
      end
    else
      result
    end
  end

  defp validate_and_mask(card, card_length) when card_length >= 14 do
    card_in_right_order = Enum.reverse(card)
    [val, skip_digits] = validate(card_in_right_order, [], card_length)

    if val, do: mask(card_in_right_order, skip_digits), else: String.reverse(List.to_string(card))
  end

  defp validate_and_mask(card, card_length) when card_length < 14 do
    String.reverse(List.to_string(card))
  end

  defp validate(card, skipped_digits, card_length) when card_length < 14 do
    [false, []]
  end

  # validate the card number, at this point it only has integers >=14
  defp validate(card, skipped_digits, card_length) when card_length >= 14 do
    [val, _] = validate(card, card_length)

    if(val || card_length < 14) do
      [val, skipped_digits]
    else
      [val, sd] = validate(tl(card), [hd(card) | skipped_digits], card_length - 1)

      [val2, sd2] =
        validate(
          Enum.slice(card, 0, length(card) - 1),
          [-List.last(card) | skipped_digits],
          card_length - 1
        )

      cond do
        val == true -> [val, sd]
        val2 == true -> [val2, sd2]
        true -> [false, []]
      end
    end
  end

  defp validate(card, card_length) when card_length >= 14 do
    # skip the last digit

    card_number = card |> Enum.filter(&(&1 != 32 && &1 != 45))

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

        [Integer.mod(Enum.sum(every_second_double), 10) == 0, []]
    end
  end

  defp validate(card, _card_length) do
    [false, []]
  end

  defp mask(card_number, skip_digits) do
    left_skip = Enum.filter(skip_digits, &(&1 >= 0))
    right_skip = Enum.filter(skip_digits, &(&1 < 0))

    mask(card_number, left_skip, right_skip)
  end

  defp mask(card_number, left_skip, right_skip) do
    masked =
      card_number
      |> Enum.drop(Enum.count(left_skip))
      |> Enum.drop(-Enum.count(right_skip))
      |> Enum.map_join(fn x ->
        if !Regex.match?(~r{ |-|\n}, to_string([x])), do: "X", else: List.to_string([x])
      end)

    left = left_skip |> Enum.reverse() |> List.to_string()
    right = right_skip |> Enum.map(fn x -> -x end) |> List.to_string()

    left <> masked <> right
  end
end
