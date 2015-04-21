# Quicksort in Elixir. Nice and tidy!

defmodule QuickSort do
  def qsort([]) do
    []
  end
  def qsort([pivot | rest]) do
    { left, right } = Enum.partition(rest, fn(x) -> x < pivot end)
    qsort(left) ++ [pivot] ++ qsort(right)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule QuickSortTest do
    use ExUnit.Case, async: true

    test "quicksort of random array of numbers" do
      assert QuickSort.qsort([2,7,5,23,78,1,12,962,2367,4,28,41,14,678,457,33,78,438,87]) == [1,2,4,5,7,12,14,23,28,33,41,78,78,87,438,457,678,962,2367]
    end

  end
end
