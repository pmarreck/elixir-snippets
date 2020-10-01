defmodule Benchmark do
  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end

count = 1000000

IO.puts "#{count} spawns takes:"
IO.puts Benchmark.measure(fn ->
	for _ <- 0..count, do: spawn fn -> nil end
end)
IO.puts "seconds"
