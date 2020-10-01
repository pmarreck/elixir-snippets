defmodule IsPowerOfTwo do
  require Bitwise
  # import Integer, only: [is_odd: 1]
  # def is_power_of_two(1), do: true
  # def is_power_of_two(num) when is_integer(num) and is_odd(num), do: false
  # def is_power_of_two(num) when is_integer(num), do: is_power_of_two(num >>> 1)
  def is_power_of_two(num) when is_integer(num) do
    Bitwise.band(num, num - 1) == 0
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule IsPowerOfTwoTest do
    use ExUnit.Case, async: true
    import IsPowerOfTwo
    use Bitwise, only_operators: true
    test "is_power_of_two" do
      assert is_power_of_two(2)
      refute is_power_of_two(3)
      assert is_power_of_two(4)
      refute is_power_of_two(5)
      assert is_power_of_two(8)
      refute is_power_of_two(9)
      refute is_power_of_two(15)
      assert is_power_of_two(16)
      refute is_power_of_two(17)
    end
  end
end
