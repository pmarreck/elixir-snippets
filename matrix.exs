defmodule Matrix do

  # this crazy clever algorithm hails from
  # http://stackoverflow.com/questions/5389254/transposing-a-2-dimensional-matrix-in-erlang
  # and is apparently from the Haskell stdlib. I implicitly trust Haskellers.
  def transpose([[x | xs] | xss]) do
    [[x | (for [h | _] <- xss, do: h)] | transpose([xs | (for [_ | t] <- xss, do: t)])]
  end

  def transpose([[] | xss]), do: transpose(xss)

  def transpose([]), do: []

  def inverse(matrix) do
    # oh shit. this rabbit hole goes DEEP
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule MatrixTest do
    use ExUnit.Case, async: true

    test "3x3 matrix transpose" do
      assert Matrix.transpose([[1,2,3],[4,5,6],[7,8,9]]) == [[1,4,7],[2,5,8],[3,6,9]]
    end
  end
end

# run this inline performance suite with "elixir #{__ENV__.file} perf"
if System.argv |> List.first == "perf" do
  # just a timing utility
  defmodule Time do
    def now, do: ({msecs, secs, musecs} = :erlang.timestamp; ((msecs*1000000 + secs)*1000000 + musecs)/1000000)
  end
  iters = 50000
  t = Time.now
  Enum.each(1..iters, fn(_) -> Matrix.transpose([[1,2,3],[4,5,6],[7,8,9]]) end)
  IO.puts "elapsed time #{Time.now - t} secs for #{iters} iterations of a 3x3 matrix transpose"
end