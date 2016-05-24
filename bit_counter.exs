defmodule BitCounter do
  use Bitwise, only_operators: true

  def count(int) do
    count(int, 0)
  end
  defp count(0, acc) do
    acc
  end
  defp count(int, acc) do
    # :erlang.band(int, int-1), without Bitwise... implementing the first of many dependencies is the easiest :O
    count(int &&& (int-1), acc + 1)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule BitCounterTest do
    use ExUnit.Case, async: true
    alias BitCounter, as: BC

    # counts easily confirmed via Integer.digits(num, 2)

    test "bit counts of 8, 5 and 69 sum to 6" do
      assert 6 == BC.count(8) + BC.count(5) + BC.count(69)
    end

  end
end
