# Inspired by Haskell
# The advantage of this way of dividing a list into parts is that
# the list doesn't have to be counted or otherwise traversed first.
# This is about 4 times faster than using Enum.chunk, and also doesn't need to determine the length of the lists first.

defmodule Collection do
  def divide(items, n), do: do_divide(items, List.duplicate([], n), [])
  defp do_divide([], o1, o2), do: o1 ++ o2
  defp do_divide([l|ls], [o|o1], o2), do: do_divide(ls, o1, [[l|o]|o2])
  defp do_divide(ls, [], o2), do: do_divide(ls, o2, [])
end

# just a timing util
defmodule RubyTime do
  def now, do: ({msecs, secs, musecs} = :erlang.timestamp; ((msecs*1000000 + secs)*1000000 + musecs)/1000000)
end

# IO.inspect Collection.divide([1,2,3,4,5,6,7,8,9,10,11,12], 3), char_lists: false

# IO.inspect Enum.chunk([1,2,3,4,5,6,7,8,9,10,11,12], 4), char_lists: false

times = 5_000_000

t = RubyTime.now
for _ <- 1..times do Collection.divide([1,2,3,4,5,6,7,8,9,10,11,12], 3) end
collectiondivide_total_time = RubyTime.now - t

t = RubyTime.now
for _ <- 1..times do Enum.chunk([1,2,3,4,5,6,7,8,9,10,11,12], 4) end
enumchunk_total_time = RubyTime.now - t

IO.puts "Running Collection.divide #{times} times takes #{collectiondivide_total_time} seconds"
IO.puts "Running Enum.chunk #{times} times takes #{enumchunk_total_time} seconds"
