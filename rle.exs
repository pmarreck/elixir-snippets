defmodule RLE do

  def encode(list), do: _encode(list, [])

  defp _encode([], result), do: Enum.reverse(result)

  defp _encode([ a, a | tail ], result) do
    _encode( [ {a, 2} | tail ], result )
  end

  defp _encode([ {a, n}, a | tail ], result) do
    _encode( [ {a, n+1} | tail ], result )
  end

  defp _encode([ a | tail], result) do
    _encode( tail, [ a | result ] )
  end

  def decode(list), do: _decode(list, [])

  defp _decode([], result), do: Enum.reverse(result)

  defp _decode([{_, 0} | tail ], result) do
    _decode(tail, result)
  end

  defp _decode([{a, n} | tail ], result) do
    _decode([{a, n-1} | tail], [ a | result ] )
  end

  defp _decode([a | tail ], result) do
    _decode( tail, [ a | result ] )
  end

end

# a test
RLE.encode([1,2,2,3,3,3,3,4,5,6,6,7,8,7,8,8,8,9,10]) == RLE.decode([1, {2, 2}, {3, 4}, 4, 5, {6, 2}, 7, 8, 7, {8, 3}, 9, 10])
