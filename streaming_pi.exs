defmodule StreamingPi do
  # @compile [:native, {:hipe, [:o3]}]

  # It might be possible to parallelize this if you precompute the states below at intervals like
  # 100, 200, ... 1000
  # then 2000, 3000, 4000... 10000 etc. and then store it somewhere.
  # Or some more clever exponentially-growing interval.
  # One thing to note though is that the intermediate values are HUGE.
  def stream(start) do
    Stream.resource(
      fn ->
        start
      end,
      fn
        {q, r, t, k, n, l, c} when 4 * q + r - t < n * t ->
        # IO.inspect(Process.info(self())) &&
          # if rem(c, 100) == 0 do
          #   IO.inspect {q, r, t, k, n, l, c}
          # end
          {[n], {q * 10, 10 * (r - n * t), t, k, div(10 * (3 * q + r), t) - 10 * n, l, c + 1}}
        {q, r, t, k, _n, l, c} ->
          {[], {q * k, (2 * q + r) * l, t * l, k + 1, div(q * 7 * k + 2 + r * l, t * l), l + 2, c}}
      end,
      fn s -> s end
    )
  end

  def stream do
    stream({1, 0, 1, 1, 3, 3, 0})
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv() |> List.first() == "test" do
  ExUnit.start(exclude: [:skip])

  defmodule PiTest do
    use ExUnit.Case, async: true
    alias StreamingPi, as: Pi

    test "first 5 Pi digits via Enum.take" do
      assert Pi.stream() |> Enum.take(6) == [3, 1, 4, 1, 5, 9]
    end

    # @tag :skip
    test "compute first 5000 Pi digits via Enum.take, then compare the last 10 digits" do
      # Note that this fails with this error if on a memory-constrained environment and the number taken is 10k:
      # eheap_alloc: Cannot allocate 762886488 bytes of memory (of type "heap").
      assert Pi.stream() |> Enum.take(5000) |> Enum.take(-10) == [7, 4, 1, 3, 2, 6, 0, 4, 7, 2]
    end
  end
else
  # run the main program
  # Example usage: time elixir streaming_pi.exs 10000
  alias StreamingPi, as: Pi
  count = System.argv() |> List.first() |> String.to_integer()
  IO.puts(:stderr, "Computing first #{count} digits of Pi...")
  raw_string = Pi.stream() |> Enum.take(count) |> Enum.join()
  <<_three, rest::binary>> = raw_string
  IO.puts "3.#{rest}"
end
