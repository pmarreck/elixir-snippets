defmodule StreamingFizzBuzz do
  def from(start) do
    Stream.resource(
      fn -> {start, fizzbuzznum(start)} end,
      fn({n, _}) ->
        t = {n+1, fizzbuzznum(n+1)}
        { [t], t }
      end,
      fn({n, fb}) ->
        {n, fb}
      end
    )
  end

  @doc """
  Simplest interface. Takes the first N fizzbuzzes.
  """
  def first(num) do
    take(num) |> Enum.map(fn({_, fb}) -> fb end)
  end

  @doc """
  Returns a fizzbuzz tuple stream starting with 0 up to num.
  """
  def take(num) do
    take(0, num)
  end

  @doc """
  Returns a fizzbuzz tuple stream starting with start up to num.
  """
  def take(start, num) do
    from(start) |> Enum.take(num)
  end

  defp fizzbuzznum(n) when rem(n, 15) == 0 do
    "fizzbuzz"
  end
  defp fizzbuzznum(n) when rem(n, 5) == 0 do
    "buzz"
  end
  defp fizzbuzznum(n) when rem(n, 3) == 0 do
    "fizz"
  end
  defp fizzbuzznum(n) do
    to_string n
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule Time do
    def now do
      {mega, s, micro} = :erlang.now
      (mega * 1000000) + s + (micro / 1000000)
    end
  end
  defmodule FizzBuzzTest do
    use ExUnit.Case, async: true
    alias StreamingFizzBuzz, as: FizzBuzz

    test "first 10 fizzbuzz via take" do
      assert [{1, "1"}, {2, "2"}, {3, "fizz"}, {4, "4"}, {5, "buzz"}, {6, "fizz"}, {7, "7"}, {8, "8"}, {9, "fizz"}, {10, "buzz"}] == (FizzBuzz.from(0) |> Enum.take(10))
    end

    test "first 15 fizzbuzz via first" do
      assert ~w[ 1 2 fizz 4 buzz fizz 7 8 fizz buzz 11 fizz 13 14 fizzbuzz ] == FizzBuzz.first(15)
    end

    test "first 10 fizzbuzz starting with 20" do
      assert [{21, "fizz"}, {22, "22"}, {23, "23"}, {24, "fizz"}, {25, "buzz"}, {26, "26"}, {27, "fizz"}, {28, "28"}, {29, "29"}, {30, "fizzbuzz"}] == FizzBuzz.take(20, 10)
    end
  end
end
