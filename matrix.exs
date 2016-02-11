defmodule Matrix do

  # this crazy clever algorithm hails from
  # http://stackoverflow.com/questions/5389254/transposing-a-2-dimensional-matrix-in-erlang
  # and is apparently from the Haskell stdlib. I implicitly trust Haskellers.
  def transpose([[x | xs] | xss]) do
    [[x | (for [h | _] <- xss, do: h)] | transpose([xs | (for [_ | t] <- xss, do: t)])]
  end
  def transpose([[] | xss]), do: transpose(xss)
  def transpose([]), do: []

  def num_cols([first_row | _]) when is_list(first_row) do
    # assumes all elements are same length
    Enum.count(first_row)
  end

  def num_rows(a) when is_list(a) do
    Enum.count(a)
  end

  # entry point /2 signature for multiply
  def multiply(a = [x | _],b = [y | _]) when is_list(a) and is_list(b) and is_list(x) and is_list(y) do
    multiply([], a, transpose(b))
  end
  # entry point for scalar x matrix multiply
  # termination case
  def multiply(_, []), do: []
  # iterative case
  def multiply(a, b = [h | t]) when is_number(a) and is_list(b) and is_list(h) do
    [Enum.map(h, &(&1*a)) | multiply(a, t)]
  end
  def multiply(b = [h | _], a) when is_number(a) and is_list(b) and is_list(h) do
    multiply(a, b)
  end
  # matrix x matrix multiply
  # "row/column mult/sum mode", /3, matches on array depth of 1
  def multiply(result, [], []), do: result
  def multiply(result, [a | rest_a], [b | rest_b]) when not is_list(a) and not is_list(b), do: multiply(a*b+result, rest_a, rest_b)

  # main multiply stuff, /3
  def multiply(result, [first_row_a | rest_a], b) when is_list(first_row_a) do
    [Enum.reverse(Enum.reduce(b, [], fn(col_b,acc) -> [multiply(0, first_row_a, col_b) | acc] end)) | multiply(result, rest_a, b)]
  end
  # termination case, no rows of A matrix left
  def multiply(result, [], _), do: result

  # matrix addition
  def add([xs | xss], [ys | yss]) when is_list(xs) and is_list(ys) do
    [add(xs, ys) | add(xss, yss)]
  end
  def add([x | xs], [y | ys]) when not is_list(x) and not is_list(y) do
    [(x + y) | add(xs, ys)]
  end
  def add([], []) do
    []
  end

  # matrix subtraction
  def subtract([xs | xss], [ys | yss]) when is_list(xs) and is_list(ys) do
    [subtract(xs, ys) | subtract(xss, yss)]
  end
  def subtract([x | xs], [y | ys]) when not is_list(x) and not is_list(y) do
    [(x - y) | subtract(xs, ys)]
  end
  def subtract([], []) do
    []
  end

  def inverse(_matrix) do
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

    test "1x3 and 3x4 matrix multiply" do
      assert Matrix.multiply([[3,4,2]],[[13,9,7,15],[8,7,4,6],[6,4,0,3]]) == [[83,63,37,75]]
    end

    test "3x2 and 2x2 matrix multiply" do
      assert Matrix.multiply([[4,8],[0,2],[1,6]],[[5,2],[9,4]]) == [[92,40],[18,8],[59,26]]
    end

    test "failure to multiply 3x3 and 2x2" do
      assert_raise FunctionClauseError, fn -> Matrix.multiply([[1,2,3],[4,5,6],[7,8,9]],[[1,2],[3,4]]) end
    end

    test "multiply 2x2 matrix by scalar (in any order)" do
      assert Matrix.multiply(2, [[1,2],[3,4]]) == [[2,4],[6,8]]
      assert Matrix.multiply([[1,2],[3,4]], 2) == [[2,4],[6,8]]
    end

    test "add 2x2 matrices" do
      assert Matrix.add([[1,2],[3,4]],[[1,2],[3,4]]) == [[2,4],[6,8]]
    end

    test "subtract 2x2 matrices" do
      assert Matrix.subtract([[1,2],[3,4]],[[1,2],[3,4]]) == [[0,0],[0,0]]
    end

    test "adding 2x2 and 3x3 fails" do
      assert_raise FunctionClauseError, fn -> Matrix.add([[1,2,3],[4,5,6],[7,8,9]],[[1,2],[3,4]]) end
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