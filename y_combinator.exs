defmodule Combinator do
  def fix(f) do
    (fn x ->
      f.(fn y -> (x.(x)).(y) end)
    end).(fn x ->
      f.(fn y -> (x.(x)).(y) end)
    end)
  end
end

# TODO: write a test for it
