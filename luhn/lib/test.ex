defmodule Test do

  def hello(list) do
    rec(list,[])
  end
  def rec([],state) do
    state
  end
  def rec([head|tail], state) do
    IO.puts inspect state
    #state = [head | head * 2]
    rec(tail, [head | state])
  end

  def rec2(list, state, direction) do
    if(length(list) >= 5) do
      [val,[]] = rec2(tl(list), [hd(list) | state], "left")
      IO.puts inspect val
    else
      IO.puts "####2. list #{inspect list}"
      IO.puts "####2.#{inspect state}"
      [false, []]
    end


    #IO.puts "####3. list #{inspect list}"
  end
  def delete_all(list, el) do
    delete_all(list, el, [])
  end

  def delete_all([head | tail], el, new_list) when head === el do
    delete_all(tail, el, new_list)
  end

  def delete_all([head | tail], el, new_list) do
    delete_all(tail, el, [head | new_list])
  end

  def delete_all([], el, new_list) do
    Enum.reverse(new_list)
  end

  def listret() do
    [false, [1,2]]
  end

end
