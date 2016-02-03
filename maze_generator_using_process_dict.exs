defmodule Maze do
  def generate(w, h, rand_seed \\ :os.timestamp) do
    :random.seed(rand_seed)
    :rand.seed(:exs64, rand_seed)
    (for i <- 1..w, j <- 1..h, do: {i,j}) |>
    Enum.each(fn{i,j} -> Process.put({:vis, i, j}, true) end)
    walk(:random.uniform(w), :random.uniform(h))
    get({w,h})
  end

  def print(w, h, rand_seed \\ :os.timestamp) do
    Maze.generate(w, h, rand_seed) |> Enum.each(&IO.puts/1)
  end

  defp walk(x, y) do
    Process.put({:vis, x, y}, false)
    Enum.each(Enum.shuffle([[x-1,y], [x,y+1], [x+1,y], [x,y-1]]), fn [i,j] ->
      if Process.get({:vis, i, j}) do
        if i == x, do: Process.put({:hor, x, max(y, j)}, "+   "),
                 else: Process.put({:ver, max(x, i), y}, "    ")
        walk(i, j)
      end
    end)
  end

  defp get({w,h}) do
    Enum.map(1..h, fn j ->
      [(Enum.map(1..w, fn i -> Process.get({:hor, i, j}, "+---") end) |> Enum.join) <> "+",
      (Enum.map(1..w, fn i -> Process.get({:ver, i, j}, "|   ") end) |> Enum.join) <> "|"]
    end) ++ [String.duplicate("+---", w) <> "+"]
    |> List.flatten
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule MazeTest do
    use ExUnit.Case, async: true

    test "5x5 output as expected" do
      assert Maze.generate(5, 5, {1454, 367294, 550155}) == [
        "+---+---+---+---+---+",
        "|                   |",
        "+   +---+---+---+   +",
        "|       |           |",
        "+   +---+   +---+---+",
        "|   |       |       |",
        "+   +---+---+---+   +",
        "|   |               |",
        "+   +   +---+---+   +",
        "|       |           |",
        "+---+---+---+---+---+"
      ]
    end

  end
end

# run this inline performance suite with "elixir #{__ENV__.file} perf"
if System.argv |> List.first == "perf" do
  # just a timing utility
  defmodule Time do
    def now, do: ({msecs, secs, musecs} = :erlang.timestamp; ((msecs*1000000 + secs)*1000000 + musecs)/1000000)
  end
  iters = 5000
  i = 20
  j = 20
  t = Time.now
  Enum.each(1..iters, fn(_) -> Maze.generate(i,j) end)
  IO.puts "elapsed time #{Time.now - t} secs for #{iters} iterations of a #{i}x#{j} maze"
end