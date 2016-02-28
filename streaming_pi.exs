defmodule StreamingPi do
  def from(start) do
    Stream.resource(
      fn -> calc(start) end,
      fn(state = {_,_,_,_,_n,_,_,curr}) ->
        state = calc(state)
        {[curr], state}
      end,
      fn(s) -> s end
    )
  end

  def stream do
    from({1,6,3,2,3,5,0,3})
  end

  defp calc({q,r,t,k,n,l,c,_curr}) when (4*q + r - t) < n*t do
    # IO.puts "Next digit: #{n}"
    # IO.puts "q=#{q}&r=#{r}&t=#{t}&k=#{k}&n=#{n}&l=#{l}&c=#{c}&curr=#{curr}"
    {q*10, 10*(r-n*t), t, k, div(10*(3*q+r), t) - 10*n, l, c+1, n}
    # calc({q*10, 10*(r-n*t), t, k, div(10*(3*q+r), t) - 10*n, l, c+1})
  end
  defp calc({q,r,t,k,_n,l,c,curr}) do
    # IO.puts "No output, just recurse with recompute"
    # IO.puts "q=#{q}&r=#{r}&t=#{t}&k=#{k}&n=#{n}&l=#{l}&c=#{c}"
    calc({q*k, (2*q+r)*l, t*l, k+1, div(q*7*k+2+r*l, t*l), l+2, c, curr})
  end


end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule PiTest do
    use ExUnit.Case, async: true
    alias StreamingPi, as: Pi

    test "first 5 Pi digits via Enum.take" do
      assert Pi.stream |> Enum.take(6) == [3,1,4,1,5,9]
    end

  end
end
