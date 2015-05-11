defmodule Upto100 do
  def go do
    explore("1", 1, {1, []})
  end

  # spillover cases

  def explore(_, current_num, _) when current_num > 9 do
  end

  # exactly 100 case
  def explore(concatenated_string, 9, {100,[]}) do
    IO.puts concatenated_string
  end

  # all other cases
  def explore(concatenated_string, current_num, _) do
    explore(concatenated_string <> to_string(current_num+1), current_num+1, Code.eval_string(concatenated_string <> to_string(current_num+1)))
    explore(concatenated_string <> "+" <> to_string(current_num+1), current_num+1, Code.eval_string(concatenated_string <> "+" <> to_string(current_num+1)))
    explore(concatenated_string <> "-" <> to_string(current_num+1), current_num+1, Code.eval_string(concatenated_string <> "-" <> to_string(current_num+1)))
  end

end

Upto100.go
