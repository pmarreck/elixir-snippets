defmodule StreamingPi do
  # @compile [:native, {:hipe, [:o3]}]

  def stream(start) do
    Stream.resource(
      fn ->
        start
      end,
      fn
        {q, r, t, k, n, l, c} when 4 * q + r - t < n * t ->
        # IO.inspect(Process.info(self())) &&
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
end
