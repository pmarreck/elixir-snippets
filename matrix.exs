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

  def num_rows(a = [h | _]) when is_list(h) do
    Enum.count(a)
  end

  def size(a = [h | _]) when is_list(h) do
    Enum.max([num_rows(a), num_cols(a)])
  end

  # count row size
  def size(a = [h | _], 1) when is_list(h) do
    num_rows(a)
  end
  # count column size
  def size(a = [h | _], 2) when is_list(h) do
    num_cols(a)
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

  # apply an fn to every element
  def arrayfun(a = [h | t], func) when is_list(a) and is_list(h) and is_function(func) do
    [Enum.map(h, func) | arrayfun(t, func)]
  end
  # terminal case
  def arrayfun([], _), do: []

  # sigmoid function, number argument
  def sigmoid(n) when is_number(n) do
    1/(1+:math.exp(-n))
  end
  # sigmoid function, matrix argument
  def sigmoid(a = [h | _]) when is_list(h) do
    arrayfun(a, &sigmoid/1)
  end

  # vector sum
  def sum([h]) when is_list(h) do
    Enum.reduce(h, 0, fn(x,acc)->x+acc end)
  end

  def sum(a = [h | t]) when is_list(h) and is_list(t) and length(h)==1 do
    sum(transpose(a))
  end

  # vector product
  def prod([h]) when is_list(h) do
    Enum.reduce(h, 1, fn(x,acc)->x*acc end)
  end

  def prod(a = [h | t]) when is_list(h) and is_list(t) and length(h)==1 do
    prod(transpose(a))
  end

  # max of a row vector
  def max([h]) when is_list(h) do
    Enum.max(h)
  end

  # max of a column vector
  def max(a = [h | t]) when is_list(h) and is_list(t) and length(h)==1 do
    max(transpose(a))
  end

  # max of a matrix
  def max(a = [h | t]) when is_list(h) and is_list(t) do
    # this could probably be rewritten to be more efficient...
    transpose(Enum.map(transpose(a), &([Enum.max(&1)])))
  end

  # max of a matrix specifying dimension
  def max(a = [h | t], 1) when is_list(h) and is_list(t) do
    Enum.map(a, &([Enum.max(&1)]))
  end

  def max(a = [h | t], 2) when is_list(h) and is_list(t) do
    # default
    max(a)
  end

  # unrolls a matrix into a 1 x n vector
  # note: taking advantage of Enum.concat does a :lists.reverse which may be suboptimal
  def unroll(a = [h | _]) when is_list(h) do
    [Enum.concat(a)]
  end

  # transpose column vectors to row vector first
  def reshape(a = [h | t], rows, cols) when is_list(h) and is_list(t) and length(h)==1 and length(a) > 1 do
    reshape(transpose(a), rows, cols)
  end
  # reshape a vector into a matrix
  # note: taking advantage of Enum.split does two :lists.reverse'als and may be suboptimal
  def reshape([h], rows, cols) when is_list(h) and rows > 0 and cols > 0 do
    {first, rest} = Enum.split(h, cols)
    [first | reshape([rest], rows-1, cols)]
  end
  # end case(s)
  def reshape(_,rows,_) when rows == 0, do: []
  def reshape([], _, _), do: []


  def inverse(_matrix) do
    # oh shit. this rabbit hole goes DEEP. Will return (?) to this eventually. May have to call out to BLAS etc
    raise "Not Implemented Yet Due To Nontriviality"
  end

  def zeros(sz) do
    List.duplicate(List.duplicate(0,sz),sz)
  end
  def zeros(rows, cols) do
    List.duplicate(List.duplicate(0,cols),rows)
  end

  def ones(sz) do
    List.duplicate(List.duplicate(1,sz),sz)
  end
  def ones(rows,cols) do
    List.duplicate(List.duplicate(1,cols),rows)
  end

  def rand(rows, cols) do
    Enum.map(0..rows-1, fn _ ->
      for _ <- 0..cols-1, do: :random.uniform
    end)
  end

  def identity(sz) do
    Enum.map(0..sz-1, fn i ->
      for j <- 0..sz-1, do: (if i==j, do: 1, else: 0)
    end)
  end
  def eye(sz), do: identity(sz)


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

    test "zeros 3x3" do
      assert Matrix.zeros(3) == [[0,0,0],[0,0,0],[0,0,0]]
    end

    test "zeros 1x3" do
      assert Matrix.zeros(1,3) == [[0,0,0]]
    end

    test "ones 3x3" do
      assert Matrix.ones(3) == [[1,1,1],[1,1,1],[1,1,1]]
    end

    test "ones 1x3" do
      assert Matrix.ones(1,3) == [[1,1,1]]
    end

    test "identity 3x3" do
      assert Matrix.identity(3) == [[1,0,0],[0,1,0],[0,0,1]]
    end

    test "eye 3x3" do
      assert Matrix.eye(3) == [[1,0,0],[0,1,0],[0,0,1]]
    end

    test "multiplying a 2x2 by identity matrix works" do
      assert Matrix.multiply([[1,2],[3,4]],Matrix.eye(2)) == [[1,2],[3,4]]
    end

    test "random 3x2 matrix" do
      # note: thanks to how Erlang behaves with regards to pseudorandoms, this should always be deterministic.
      # If it ever fails, then check the docs on :random (or whatever was used) to see what changed.
      # Most likely you'll just have to copy and paste the new random values here to revalidate this assertion
      assert Matrix.rand(3,2) == [[0.4435846174457203, 0.7230402056221108], [0.94581636451987, 0.5014907142064751], [0.311326754804393, 0.597447524783298]]
    end

    test "size of 3x2 == 3 and 1x4 == 4" do
      assert Matrix.size([[1,2],[3,4],[5,6]]) == 3
      assert Matrix.size([[1,2,3,4]]) == 4
    end

    test "size of 3x2 matrix specifying which dimension" do
      m = [[1,2],[3,4],[5,6]]
      assert Matrix.size(m, 1) == 3
      assert Matrix.size(m, 2) == 2
    end

    test "apply a function to every element" do
      assert Matrix.arrayfun([[2,4,6,8],[10,12,14,16]], fn x -> x/2 end) == [[1,2,3,4],[5,6,7,8]]
    end

    test "sigmoid function, number arg" do
      assert Matrix.sigmoid(0) == 0.5
      assert Matrix.sigmoid(1) == 0.7310585786300049
    end

    test "sigmoid function, matrix arg" do
      assert Matrix.sigmoid([[0,1],[1,0]]) == [[0.5,0.7310585786300049],[0.7310585786300049,0.5]]
    end

    test "sum of a vector" do
      assert Matrix.sum([[1,2,3]]) == 6
      assert Matrix.sum([[1],[2],[3]]) == 6
      assert_raise FunctionClauseError, fn -> Matrix.sum([[1,2],[3,4]]) end
    end

    test "product of a vector" do
      assert Matrix.prod([[2,4,6]]) == 48
      assert Matrix.prod([[2],[4],[6]]) == 48
      assert_raise FunctionClauseError, fn -> Matrix.prod([[1,2],[3,4]]) end
    end

    test "max of a vector" do
      assert Matrix.max([[1,8,5,12,6]]) == 12
      assert Matrix.max([[1],[8],[5],[12],[6]]) == 12
    end

    test "max of a matrix" do
      assert Matrix.max([[1,2],[3,4],[5,6]]) == [[5, 6]]
    end

    test "max of a matrix specifying dimension" do
      assert Matrix.max([[1,2],[3,4],[5,6]], 1) == [[2],[4],[6]]
      assert Matrix.max([[1,2],[3,4],[5,6]], 2) == [[5, 6]]
    end

    test "max of an entire matrix" do
      assert Matrix.max(Matrix.max([[2,4,6,8],[10,12,16,14]])) == 16 # [[16]]?
    end

    # # Octave uses 1-based indexing, which is shite, so we will assume 0-based unless otherwise specified
    # test "max also returning index in tuple, assume 0-based indexing" do
    #   assert Matrix.max_with_index([[2,4,6,8]]) == {8, 3}
    #   assert Matrix.max_with_index([[2],[4],[6],[8]]) == {8, 3}
    # end

    # test "max also returning index in tuple, specify 0-based indexing" do
    #   assert Matrix.max_with_index0([[2,4,6,8]]) == {8, 3}
    #   assert Matrix.max_with_index0([[2],[4],[6],[8]]) == {8, 3}
    # end

    # test "max also returning index in tuple, specify 1-based indexing" do #like Octave. WHY??
    #   assert Matrix.max_with_index1([[2,4,6,8]]) == {8, 4}
    #   assert Matrix.max_with_index1([[2],[4],[6],[8]]) == {8, 4}
    # end

    test "unroll a matrix into a vector" do
      assert Matrix.unroll([[2,4,6,8],[10,12,14,16]]) == [[2,4,6,8,10,12,14,16]]
    end

    test "reshape a vector into a matrix" do
      assert Matrix.reshape([[1,2,3,4,5,6]],3,2) == [[1,2],[3,4],[5,6]]
      assert Matrix.reshape([[1],[2],[3],[4],[5],[6]],2,3) == [[1,2,3],[4,5,6]]
    end

    test "consecutive unroll and reshape preserves" do
      assert Matrix.reshape(Matrix.unroll([[1,2],[3,4],[5,6]]),3,2) == [[1,2],[3,4],[5,6]]
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
  t = Time.now
  Enum.each(1..iters, fn(_) -> Matrix.multiply([[1,2,3],[4,5,6],[7,8,9]],[[1,2,3],[4,5,6],[7,8,9]]) end)
  IO.puts "elapsed time #{Time.now - t} secs for #{iters} iterations of a 3x3 x 3x3 matrix multiply"
  a = Matrix.rand(100,100)
  b = Matrix.rand(100,100)
  t = Time.now
  iters = 100
  Enum.each(1..iters, fn(_) -> Matrix.multiply(a,b) end)
  IO.puts "elapsed time #{Time.now - t} secs for #{iters} iterations of a 100x100 x 100x100 matrix multiply"
end
