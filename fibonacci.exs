defmodule Fib do

  def run_recursive(num) do
    run_recursive(num, 0, 1)
  end
  # FYI: tail call optimized
  def run_recursive(0, res, _), do: res
  def run_recursive(n, res, nxt) when n > 0 do
    run_recursive(n-1, nxt, res+nxt)
  end

  def run_enumerative(0), do: 0
  def run_enumerative(num) when num > 0 and is_integer(num) do
    {_, total} = Enum.reduce((1..num), {1,0}, fn(_, {a,b}) -> {a+b,a} end)
    total
  end

  def run_streaming(0), do: 0
  def run_streaming(num) when num > 0 and is_integer(num) do
    {:ok, {total, _}} = Stream.iterate({0, 1}, fn {a, b} -> {b, a+b} end) |> Enum.fetch num
    total
  end

end

# just a timing utility
defmodule Time do
  def now, do: ({msecs, secs, musecs} = :erlang.now; ((msecs*1000000 + secs)*1000000 + musecs)/1000000)
end


times = 1000000

t = Time.now
Fib.run_recursive times
recursive_total_time = Time.now - t

t = Time.now
Fib.run_enumerative times
enumerative_total_time = Time.now - t

t = Time.now
Fib.run_streaming times
streaming_total_time = Time.now - t

IO.puts "Running Elixir recursive fib(#{times}) takes #{recursive_total_time} seconds"
IO.puts "Running Elixir enumerative fib(#{times}) takes #{enumerative_total_time} seconds"
IO.puts "Running Elixir streaming fib(#{times}) takes #{streaming_total_time} seconds"
