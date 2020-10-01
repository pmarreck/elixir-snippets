defmodule Combinator do
  def fix(f) do
    (fn x ->
      f.(fn y -> (x.(x)).(y) end)
    end).(fn x ->
      f.(fn y -> (x.(x)).(y) end)
    end)
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule CombinatorTest do
    use ExUnit.Case, async: true
    alias Combinator, as: C

    test "calling anonymous function recursively that does factorial" do
      fact = C.fix(fn
                     this_function ->
                     fn
                       0 -> 1
                       x when x > 0 -> x * this_function.(x-1)
                     end
                   end)
      assert 120 == fact.(5)
    end

  end
end
