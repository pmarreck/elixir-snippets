defmodule Collection do
  def divide(items, n), do: do_divide(items, List.duplicate([], n), [])
  defp do_divide([], o1, o2), do: o1 ++ o2
  defp do_divide([l|ls], [o|o1], o2), do: do_divide(ls, o1, [[l|o]|o2])
  defp do_divide(ls, [], o2), do: do_divide(ls, o2, [])
end

IO.puts IO.inspect Collection.divide([1,2,3,4,5,6,7,8,9,0], 3)
