#!/usr/bin/env elixir

# rpn_forth_thing.exs
# A commandline RPN calculator in Elixir... just for practice.

# Aaaand I seem to be adding bits of Forth (and Forth-inspired) here and there. For fun, of course.
# Aaaand it's now good enough to define and use named functions. And do conditional branching.
# I'm pretty sure it is good enough to do fizzbuzz or deal poker cards,
# but that's left as an exercise for the reader... or until I get bored again...

# Usage: rpn_forth_thing.exs 1 2 3 \* +  #=> 7
# Note that you have to escape * (to multiply the top 2 items on the stack)
# as well as ';', due to your shell intercepting it
# and doing shell expansion or whatnot instead. ;)
# You can use any of the commands defined below in the "compute" clauses.
# Note that you can define your own names using ':' ending in ';', ex:
# rpn_forth_thing.exs : square dup \* \; 10 square
#=> 100

# Finally got nested loops to work. Stack pointers are just references in elixir lol
# Basically going through implementing all the functionality illustrated at:
# https://www.forth.com/starting-forth/

defmodule RPNForthThing do

  def initialize do
    initialize(System.argv)
  end
  def initialize(input) when is_binary(input) do
    initialize(String.split(input, ~r/\s+/))
  end
  def initialize(input) when is_list(input) do
    input |> normalize |> compute([], [], Map.new)
  end

  def normalize(input) when is_list(input) do
    input
    |> Enum.map(fn(elem) ->
       num_or_atom = validate_num(elem)
       if num_or_atom == :NaN do
         # String.to_atom(elem)
         elem
       else
         num_or_atom
       end
    end #fn
    ) #Enum.map
  end

  # defp validate_num(num) when is_float(num), do: num
  defp validate_num(num) when is_integer(num), do: num
  defp validate_num(num) when is_binary(num) do
    cond do
      num =~ ~r/^-?[0-9]+$/              -> String.to_integer(num)
      # num =~ ~r/^-?[0-9]+(?:\.[0-9]+)?$/ -> String.to_float(num)
      true                           -> :NaN
    end
  end

  # when no instructions left and one item on data stack, just return that
  def compute([], [last_val], _, _) do
    last_val
  end

  # when no items left on either instruction or data stack, just bail
  def compute([], [], _, _) do
    # just bail
  end

  # when no instructions left, just return data stack
  def compute([], data_stack, _, _) when is_list(data_stack) do
    data_stack
  end

  def compute([ "end" | _ ], [last_elem_in_data_stack], [], _) do
    last_elem_in_data_stack
  end

  def compute([ "end" | _ ], data_stack, [], _) when is_list(data_stack) do
    data_stack
  end

  def compute([ "do" | remainder ], [x, y | data_stack], return_stack, dict) do
    # The way this works is:
    # DO moves the index (0) and the control (5) over to the return stack.
    # I copies the top of the return stack to the data stack.
    # LOOP increments the index (top of return stack).
    # If the index is less than the control (one below the top of return stack),
    # then it reruns the commands from DO back to LOOP.
    # If the index is >=, then it pops the index and control from the
    # return stack, and control resumes as normal.
    compute(remainder, data_stack, [x, y, %{do: remainder} | return_stack], dict)
  end

  def compute([ "i" | remainder ], data_stack, [x, _y, %{do: _do_block} | _rest_of_return_stack] = return_stack, dict) do
    compute(remainder, [x | data_stack], return_stack, dict)
  end

  # note implementation difference/similarity to "i". "i" assumes a loop already on the return stack
  # (and pattern-matches on that), r@ does not
  def compute([ "r@" | remainder ], data_stack, [x | _rest_of_return_stack] = return_stack, dict) do
    compute(remainder, [x | data_stack], return_stack, dict)
  end

  def compute([ ">r" | remainder ], [n | data_stack], return_stack, dict) do
    compute(remainder, data_stack, [n | return_stack], dict)
  end

  def compute([ "r>" | remainder ], data_stack, [n | return_stack], dict) do
    compute(remainder, [n | data_stack], return_stack, dict)
  end

  def compute([ "j" | remainder ], data_stack, [_x, _y, %{do: _do_block}, z | _rest_of_return_stack] = return_stack, dict) do
    compute(remainder, [z | data_stack], return_stack, dict)
  end

  # loops. holy crap NESTED LOOPS WORK.
  def compute([ "loop" | remainder ], data_stack, [x, y, %{do: do_block} | return_stack], dict) do
    x = x + 1
    if x < y do
      compute(do_block, data_stack, [x, y, %{do: do_block} | return_stack], dict)
    else
      compute(remainder, data_stack, return_stack, dict)
    end
  end

  # quoted string output
  def compute([".\"" | remaining_input ], data_stack, return_stack, dict) do
    {to_print, [_closequote | rest]} = Enum.split_while(remaining_input, fn(ins) -> ins != "\"" end)
    IO.write(Enum.join(to_print, " "))
    # IO.write(" ") # is this necessary to match the spec?
    compute(rest, data_stack, return_stack, dict)
  end

  def compute([ "+" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [x + y | data_stack], return_stack, dict)
  end

  def compute([ "2+" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [x + 2 | data_stack], return_stack, dict)
  end

  def compute([ "-" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [x - y | data_stack], return_stack, dict)
  end

  def compute([ "2-" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [x - 2 | data_stack], return_stack, dict)
  end

  def compute([ "*/" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(["*", x, "/" | remaining_input], data_stack, return_stack, dict)
  end

  def compute([ "/mod" | remaining_input], [x, y | data_stack], return_stack, dict) do
    compute(remaining_input, [div(y, x), rem(y, x) | data_stack], return_stack, dict)
  end

  def compute([ "*/mod" | remaining_input], [x, y, z | data_stack], return_stack, dict) do
    compute(remaining_input, [rem(x*y, z), div(x*y, z) | data_stack], return_stack, dict)
  end

  def compute([ "*" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [x * y | data_stack], return_stack, dict)
  end

  def compute([ "2*" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [x * 2 | data_stack], return_stack, dict)
  end

  def compute([ "/" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [trunc(x / y) | data_stack], return_stack, dict)
  end

  def compute([ "2/" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [trunc(x / 2) | data_stack], return_stack, dict)
  end

  def compute([ "**" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [trunc(:math.pow(x, y)) | data_stack], return_stack, dict)
  end

  # note: allowing these conflicts with integer-only arithmetic
  def compute([ "pi" | remaining_input], data_stack, return_stack, dict) do
    compute(remaining_input, [:math.pi | data_stack], return_stack, dict)
  end

  def compute([ "sin" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [:math.sin(x) | data_stack], return_stack, dict)
  end

  def compute([ "cos" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [:math.cos(x) | data_stack], return_stack, dict)
  end

  def compute([ "tan" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [:math.tan(x) | data_stack], return_stack, dict)
  end

  def compute([ "sqrt" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [:math.sqrt(x) | data_stack], return_stack, dict)
  end

  def compute([ "drop" | remaining_input], [_ | data_stack], return_stack, dict) do
    compute(remaining_input, data_stack, return_stack, dict)
  end

  def compute([ "dup" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [x, x | data_stack], return_stack, dict)
  end

  def compute([ "swap" | remaining_input], [y, x | data_stack], return_stack, dict) do
    compute(remaining_input, [x, y | data_stack], return_stack, dict)
  end

  def compute([ "over" | remaining_input], [x, y | data_stack], return_stack, dict) do
    compute(remaining_input, [y, x, y | data_stack], return_stack, dict)
  end

  # In-place decrement
  def compute([ "1-" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [(x - 1) | data_stack], return_stack, dict)
  end

  # In-place increment
  def compute([ "1+" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [(x + 1) | data_stack], return_stack, dict)
  end

  # In-place negation
  def compute([ "@-" | remaining_input], [x | data_stack], return_stack, dict) do
    compute(remaining_input, [-x | data_stack], return_stack, dict)
  end

  # negate (similar)
  def compute([ "negate" | remaining_input], [n | data_stack], return_stack, dict) do
    compute(remaining_input, [-n | data_stack], return_stack, dict)
  end

  # random numbers
  def compute([ "rand" | remaining_input], data_stack, return_stack, dict) do
    compute(remaining_input, [:rand.uniform | data_stack], return_stack, dict)
  end

  # max
  def compute([ "max" | remaining_input], [a, b | data_stack], return_stack, dict) do
    max = case a < b do
      true -> b
      false -> a
    end
    compute(remaining_input, [max | data_stack], return_stack, dict)
  end

  # min
  def compute([ "min" | remaining_input], [a, b | data_stack], return_stack, dict) do
    min = case a < b do
      true -> a
      false -> b
    end
    compute(remaining_input, [min | data_stack], return_stack, dict)
  end

  # abs
  def compute([ "abs" | remaining_input], [n | data_stack], return_stack, dict) do
    compute(remaining_input, [abs(n) | data_stack], return_stack, dict)
  end

  # inspection. just spits out the remaining instructions, and the data_stack and dict states
  # Sort of, shockingly simple?
  def compute([ "inspect" | remaining_input], data_stack, return_stack, dict) do
    IO.puts "Remaining instructions:"
    IO.inspect remaining_input
    IO.puts "Data Stack:"
    IO.inspect data_stack
    IO.puts "Return Stack:"
    IO.inspect return_stack
    IO.puts "Dictionary:"
    IO.inspect dict
    compute(remaining_input, data_stack, return_stack, dict)
  end

  # Logic/Booleans
  # For the purposes of the following logic, zero is false,
  # anything else is true... although typically a 1 is returned
  # for truths, boolean tests should compare with 0 (falsity) instead of 1

  def compute([ "=" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if y == x, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "<>" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if y != x, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "<" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if x < y, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "<=" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if x <= y, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ ">" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if x > y, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ ">=" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if x >= y, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "and" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if ((y != 0) and (x != 0)), do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "or" | remaining_input], [y, x | data_stack], return_stack, dict) do
    out = if ((y != 0) or (x != 0)), do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  def compute([ "not" | remaining_input], [x | data_stack], return_stack, dict) do
    out = if x == 0, do: 1, else: 0
    compute(remaining_input, [out | data_stack], return_stack, dict)
  end

  # If-Else-Then
  # Note that this is a prefix function!
  # Usage: test_val is on top of data_stack. "if <then-clause> else <else-clause> then"
  # puts then-clause on top of instruction data_stack if test_val != 0, else-clause if test_val == 0.
  def compute([ "if" | remaining_input], [x | data_stack], return_stack, dict) do
    {if_and_possibly_else_clause, ["then" | remaining_input]} = Enum.split_while(remaining_input, fn(ins) -> ins != "then" end)
    {if_clause, else_clause} =
      if Enum.any?(if_and_possibly_else_clause, fn ins -> ins == "else" end) do
        {if_clause, else_match} = Enum.split_while(if_and_possibly_else_clause, fn(ins) -> ins != "else" end)
        ["else" | else_clause_without_else] = else_match
        {if_clause, else_clause_without_else}
      else
        {if_and_possibly_else_clause, []}
      end
    if x != 0 do
      compute(if_clause ++ remaining_input, data_stack, return_stack, dict)
    else
      compute(else_clause ++ remaining_input, data_stack, return_stack, dict)
    end
  end

  # Rotation
  # Rotation of an entire list, in elixir, is slow by default.
  # I'm commenting these out for now till I come up with a better implementation.
  # Instead I'll use rot3^ and rot3v to just manipulate the top 3 elements of the data_stack.

  # This one doesn't work yet because it would be slow as hell
  # def compute([ :"rot^" | remaining_input], data_stack, return_stack, dict) do
  #   compute(remaining_input, ???, return_stack, dict)
  # end

  # This one works but is likely slow
  # def compute([ :"rotv" | remaining_input], [head | data_stack], return_stack, dict) do
  #   compute(remaining_input, data_stack ++ [head], return_stack, dict)
  # end

  # Rotate the top 3 values on the data_stack down (assuming top element is bottom-most, like an RPN calculator)
  def compute([ "rot3v" | remaining_input], [x, y, z | data_stack], return_stack, dict) do
    compute(remaining_input, [y, z, x | data_stack], return_stack, dict)
  end

  # Rotate the top 3 values on the data_stack up (assuming top element is bottom-most, like an RPN calculator)
  def compute([ "rot3^" | remaining_input], [x, y, z | data_stack], return_stack, dict) do
    compute(remaining_input, [z, x, y | data_stack], return_stack, dict)
  end

  # Assume "rot" is equivalent to "rot3^" for now
  def compute([ "rot" | remaining_input], [x, y, z | data_stack], return_stack, dict) do
    compute(remaining_input, [z, x, y | data_stack], return_stack, dict)
  end

  def compute([ "-rot" | remaining_input], data_stack, return_stack, dict) when is_list(data_stack) do
    compute(["rot", "rot" | remaining_input], data_stack, return_stack, dict)
  end

  # Comments
  def compute([ "(" | remaining_input ], data_stack, return_stack, dict) do
    {_, [")" | remainder]} = Enum.split_while(remaining_input, fn(ins) -> ins != ")" end)
    compute(remainder, data_stack, return_stack, dict)
  end

  # new definitions!
  def compute([ ":", name | remaining_input ], data_stack, return_stack, dict) do
    {definition, [";" | remainder]} = Enum.split_while(remaining_input, fn(ins) -> ins != ";" end)
    compute(remainder, data_stack, return_stack, Map.put(dict, name, {:word, definition}))
  end

  # new variables! (store in dictionary)
  # ideally in future it will error if it already exists as a name in the dict
  def compute([ "variable", name | remaining_input ], data_stack, return_stack, dict) do
    compute(remaining_input, data_stack, return_stack, Map.put(dict, name, {:var, nil}))
  end

  # new constants!
  # just, eh, treat as another dictionary entry for now
  # ideally in future it will error if you try to reassign a constant
  def compute([ "constant", name | remaining_input ], [x | data_stack], return_stack, dict) do
    compute(remaining_input, data_stack, return_stack, Map.put(dict, name, {:const, x}))
  end

  # store value in variable
  def compute([ "!" | remaining_input ], [name, x | data_stack], return_stack, dict) do
    if !Map.has_key?(dict, name), do: raise "Variable was not declared first: #{name}"
    compute(remaining_input, data_stack, return_stack, %{dict | name => {:var, x}})
  end

  # increment value in variable
  def compute([ "+!" | remaining_input ], [name, x | data_stack], return_stack, dict) do
    if !Map.has_key?(dict, name), do: raise "Variable was not declared first: #{name}"
    if dict[name] == {:var, nil}, do: raise "Variable cannot be incremented without being set first: #{name}"
    {:var, val} = dict[name]
    compute(remaining_input, data_stack, return_stack, %{dict | name => {:var, val + x}})
  end

  # retrieve value from variable
  def compute([ "@" | remaining_input ], [ name | data_stack], return_stack, dict) do
    if !Map.has_key?(dict, name), do: raise "Variable is undefined: #{name}"
    {:var, val} = dict[name]
    compute(remaining_input, [val | data_stack], return_stack, dict)
  end

  # side effects!
  # Prints the binary of an ascii value on the top of the data_stack (without carriage return), popping it
  def compute([ "emit" | remaining_input], [x | data_stack], return_stack, dict) do
    IO.write <<x>>
    compute(remaining_input, data_stack, return_stack, dict)
  end

  # Prints the literal value of the top of the data_stack, popping it
  def compute([ "." | remaining_input], [x | data_stack], return_stack, dict) do
    IO.write "#{x} "
    compute(remaining_input, data_stack, return_stack, dict)
  end

  # Outputs the entire data_stack but leaves it alone
  def compute([ ".s" | remaining_input], data_stack, return_stack, dict) when is_list(data_stack) do
    data_stack
    |> Enum.reverse
    |> Enum.each(fn x -> IO.write "#{x} " end)
    compute(remaining_input, data_stack, return_stack, dict)
  end

  # Emits a carriage return
  def compute([ "cr" | remaining_input], data_stack, return_stack, dict) do
    IO.puts ""
    compute(remaining_input, data_stack, return_stack, dict)
  end

  # Dictionary and variable definition lookup
  def compute([ name | remaining_input], data_stack, return_stack, dict) when is_binary(name) do
    {type, val} = if Map.has_key?(dict, name) do
      dict[name]
    else
      {:unk, name}
    end
    {ri, ds, rs, dict} = case {type, val} do
      {:word, val} when is_list(val) -> {val ++ remaining_input, data_stack, return_stack, dict}
      {:var, _} -> {remaining_input, [name | data_stack], return_stack, dict}
      {:const, val} -> {remaining_input, [val | data_stack], return_stack, dict}
      {:unk, val} -> {remaining_input, [val | data_stack], return_stack, dict}
      _           -> raise "Undefined name: #{name}"
    end
    compute(ri, ds, rs, dict)
  end

  # fallthrough... just passes things through to the data_stack (like numeric values)
  def compute([n | remaining_input], data_stack, return_stack, dict) when is_integer(n) or is_float(n) do
    compute(remaining_input, [n | data_stack], return_stack, dict)
  end

end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule RPNForthThingTest do
    use ExUnit.Case, async: true

    import ExUnit.CaptureIO

    test "normalizing input list" do
      assert RPNForthThing.normalize(["1", "5", "+"]) === [1, 5, "+"]
    end

    test "adding 2 numbers" do
      assert RPNForthThing.initialize(~w[1 2 +]) === 3
    end

    test "increment 2" do
      assert RPNForthThing.initialize(~w[1 2+]) === 3
    end

    test "subtracting 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 -]) === 1
    end

    test "decrement 2" do
      assert RPNForthThing.initialize(~w[2 2-]) === 0
    end

    test "multiplying 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 *]) === 6
    end

    test "multiply by 2" do
      assert RPNForthThing.initialize(~w[ 3 2* ]) === 6
    end

    test "dividing 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 /]) === 1
    end

    test "dividing by 2" do
      assert RPNForthThing.initialize(~w[ 6 2/ ]) === 3
    end

    test "sequence of simple math operations" do
      assert RPNForthThing.initialize(~w[ 1 2 3 4 5 * + + + 2 /]) === 13
    end

    test "power" do
      assert RPNForthThing.initialize(~w[ 10 3 ** ]) === 1000
    end

    test "abs" do
      assert RPNForthThing.initialize(~w[ -5 abs ]) === 5
    end

    test "negate" do
      assert RPNForthThing.initialize(~w[ 5 negate ]) === -5
    end

    test "pi" do
      assert RPNForthThing.initialize(~w[ pi ]) === 3.141592653589793
    end

    test "sin" do
      assert RPNForthThing.initialize(~w[ 3 sin ]) === 0.1411200080598672
    end

    test "cos" do
      assert RPNForthThing.initialize(~w[ 3 cos ]) === -0.9899924966004454
    end

    test "tan" do
      assert RPNForthThing.initialize(~w[ 3 tan ]) === -0.1425465430742778
    end

    test "sqrt" do
      assert RPNForthThing.initialize(~w[ 3 sqrt ]) === 1.7320508075688772
    end

    test "drop" do
      assert RPNForthThing.initialize(~w[ 3 3 drop ]) === 3
    end

    test "dup" do
      assert RPNForthThing.initialize(~w[ 3 dup * ]) === 9
    end

    test "swap" do
      assert RPNForthThing.initialize(~w[ 3 6 swap / ]) === 2
    end

    test "over" do
      assert RPNForthThing.initialize(~w[ 4 5 over ]) == [4, 5, 4]
    end

    test "defining new words" do
      assert RPNForthThing.initialize(~w[ : square dup * ; 5 square ]) === 25
    end

    # Note: Logic assertions only compare equal to or not equal to zero (false)
    # due to uncertain semantics around truthy values (currently defined as "anything not zero")
    test "comparisons" do
      assert RPNForthThing.initialize(~w[ 5 5 = ]) != 0
      assert RPNForthThing.initialize(~w[ 5 5 <> ]) == 0
      assert RPNForthThing.initialize(~w[ 5 4 < ]) == 0
      assert RPNForthThing.initialize(~w[ 5 4 > ]) != 0
      assert RPNForthThing.initialize(~w[ 5 5 >= ]) == 1
      assert RPNForthThing.initialize(~w[ 5 5 <= ]) == 1
    end

    test "increment and decrement" do
      assert RPNForthThing.initialize(~w[ 3 1+ ]) == 4
      assert RPNForthThing.initialize(~w[ 3 1- ]) == 2
    end

    test "unary negation" do
      assert RPNForthThing.initialize(~w[ -3 @- ]) == 3
    end

    test "if else then" do
      assert RPNForthThing.initialize(~w[ 3 5 < if 33 else 44 then ]) == 33
      # assert RPNForthThing.initialize(~w[ 3 5 < ? 33 44 ]) == 33
      assert RPNForthThing.initialize(~w[ 3 5 > if 33 else 44 then ]) == 44
      # assert RPNForthThing.initialize(~w[ 3 5 > ? 33 44 ]) == 44
    end

    test "nested if else then" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ 5 dup 3 < if ." greater " else 7 < if ." lesser " else ." equal " then then ])
      end) == "lesser"
    end

    test "if then, NO else" do
      assert RPNForthThing.initialize(~w[ 3 5 < if 33 then ]) == 33
    end

    test "and or not" do
      assert RPNForthThing.initialize(~w[ 3 5 < 8 6 > and ]) != 0
      assert RPNForthThing.initialize(~w[ 3 5 < 8 6 < and ]) == 0
      assert RPNForthThing.initialize(~w[ 3 5 < 8 6 < or ]) != 0
      assert RPNForthThing.initialize(~w[ 3 5 > 8 6 < or ]) == 0
      assert RPNForthThing.initialize(~w[ 3 5 < 8 6 < and not ]) != 0
      assert RPNForthThing.initialize(~w[ 3 5 < 8 6 < or not ]) == 0
    end

    test "rotate top 3 elements of stack up" do # what's "up" on a stack? Assumes the last element of the stack is on the bottom in the minds' eye
      assert RPNForthThing.initialize(~w[ 2 4 8 rot3^ / / ]) == 1
    end

    test "rotate top 3 elements of stack down" do
      assert RPNForthThing.initialize(~w[ 8 4 2 rot3v / / ]) == 1
    end

    # test "rotate entire stack up" do # what's "up" on a stack? Assumes the last element of the stack is on the bottom in the minds' eye
    #   assert RPNForthThing.initialize(~w[ 1 2 3 rot^ / / ]) == 0.6666666666666666
    # end

    # test "rotate entire stack down" do # what's "up" on a stack? Assumes the last element of the stack is on the bottom in the minds' eye
    #   assert RPNForthThing.initialize(~w[ 1 2 3 rotv / / ]) == 6.0
    # end

    test "define a commented square function and use it" do
      assert RPNForthThing.initialize(~w[
        ( Compute the square of the top of the stack and leave it on the stack. )
        : square dup * ;
        10 square
      ]) == 100
    end

    test "Forth example straight out of A Brief Introduction To Forth" do
      # http://users.ece.cmu.edu/~koopman/forth/hopl.html
      assert RPNForthThing.initialize(~w[
        : SQUARED        ( n -- nsquared ) dup * ;
        : SUM-OF-SQUARES ( a b -- c      ) SQUARED swap SQUARED + ;
        3 4 SUM-OF-SQUARES
      ]) == 25
    end

    test "defining and using factorial" do
      # crap, I need a rot3 or something. brb... Done.
      assert RPNForthThing.initialize(~w[
        ( Checks if we've decremented below 1; if not, recurse )
        : inner_factorial dup 1 > if dup rot3^ * swap 1- inner_factorial else drop then ;
        ( Entry point. Pushes a running total onto the stack and swaps )
        : factorial 1 swap inner_factorial ;
        6 factorial
      ]) == 720
      # Well holy shit, it passes.
    end

    test "emit" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ 101 emit ])
      end) == "e"
    end

    test "carriage return" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ cr end ])
      end) == "\n"
    end

    test "emit looped numbers" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ 10 0 do i emit loop ])
      end) == <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9>>
    end

    test "print looped numbers" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ 10 0 do i . loop ])
      end) == "0 1 2 3 4 5 6 7 8 9 "
    end

    test "print stack (peek)" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[ 1 2 3 rot .s ])
      end) == "2 3 1 "
    end

    test "print stars" do
      # example from https://github.com/dsevilla/uForth
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          : STAR 42 emit ;
          : STARS 0 do STAR loop ;
          20 STARS end
        ])
      end) == "********************"
    end

    test "DO LOOP test with I" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          5 0 do i . loop
        ])
      end) == "0 1 2 3 4 "
    end

    test "nested loops" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          : STAR 42 emit ;
          : DASH 45 emit ;
          : STARDASHES 0 do 2 0 do STAR loop 2 0 do DASH loop loop ;
          5 STARDASHES end
        ])
      end) == "**--**--**--**--**--"
    end

    test "looping negative numbers in a definition" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          : SAMPLE  -243 -250 do i . loop ; SAMPLE
        ])
      end) == "-250 -249 -248 -247 -246 -245 -244 "
    end

    test "multiplication loop" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          : MULTIPLICATIONS  cr 11 1 do  dup i * .  loop  drop ; 7 MULTIPLICATIONS
        ])
      end) == "\n7 14 21 28 35 42 49 56 63 70 "
    end

    test "*/ and R%, sticking to integers and not floats" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          : R%  10 */  5 +  10 / ;
          227 32 R% .
        ])
      end) == "73 "
    end

    test "/mod" do
      assert capture_io(fn -> RPNForthThing.initialize(~w[
        22 4 /mod . .
      ]) end) == "5 2 "
    end

    # may be wrong
    test "*/mod" do
      assert RPNForthThing.initialize(~w[
        8 10 3 */mod
      ]) == [6, 3]
    end

    test "rand doesn't error" do
      rand = RPNForthThing.initialize(~w[ rand ])
      assert rand > 0
      assert rand < 1
    end

    test "max" do
      assert RPNForthThing.initialize(~w[ 5 40 max ]) == 40
      assert RPNForthThing.initialize(~w[ 40 5 max ]) == 40
    end

    test "min" do
      assert RPNForthThing.initialize(~w[ 5 40 min ]) == 5
      assert RPNForthThing.initialize(~w[ 40 5 min ]) == 5
    end

    test "floor5" do
      assert RPNForthThing.initialize(~w[ : FLOOR5 ( n -- n' ) 1- 5 max ; 1 FLOOR5]) == 5
      assert RPNForthThing.initialize(~w[ : FLOOR5 ( n -- n' ) 1- 5 max ; 10 FLOOR5]) == 9
    end

    test "inline string output" do
      assert capture_io(fn ->
        RPNForthThing.initialize(~w[
          ." this is a test "
        ])
      end) == "this is a test"
    end

    test "eggsize computation with nested IFs and quoted text" do
      assert capture_io(fn -> RPNForthThing.initialize(~w[
        : EGGSIZE
        dup  18 < if  ." reject "      else
        dup  21 < if  ." small "       else
        dup  24 < if  ." medium "      else
        dup  27 < if  ." large "       else
        dup  30 < if  ." extra large " else
                      ." error "
        then then then then then drop ;
        29 EGGSIZE
      ]) end) == "extra large"
    end

    test "quadratic equation using return stack operators" do
      assert RPNForthThing.initialize(~w[
        : QUADRATIC  ( a b c x -- n )
        >r swap rot r@ * + r> * + ;
        2 7 9 3 QUADRATIC
      ]) == 48
    end

    test "Temp conversions" do
      assert RPNForthThing.initialize(~w[
        : F>C  ( fahr -- cels )  32 - 10 18 */ ;
        : C>F  ( cels -- fahr )  18 10 */ 32 + ;
        : C>K  ( cels -- kelv )  273 + ;
        : K>C  ( kelv -- cels )  273 - ;
        : F>K  ( fahr -- kelv )  F>C C>K ;
        : K>F  ( kelv -- fahr )  K>C C>F ;
        10 F>K 100 K>F
      ]) == [-279, 261]
    end

    test "somewhat complex variable example" do
      assert capture_io(fn -> RPNForthThing.initialize(~w[
        : ? @ . ;
        variable DATE
        variable MONTH
        variable YEAR
        : !DATE YEAR ! DATE ! MONTH ! ;
        7 31 3 !DATE
        : .DATE MONTH ? DATE ? YEAR ? ;
        .DATE
      ]) end) == "7 31 3 "
    end

    test "egg counting example" do
      assert capture_io(fn -> RPNForthThing.initialize(~w[
        : ? @ . ;
        variable EGGS
        12 constant DOZEN
        : RESET 0 EGGS ! ;
        : EGG   1 EGGS +! ;
        : CARTON DOZEN EGGS +! ;
        RESET
        EGG
        EGG
        CARTON
        EGG
        EGGS ?
      ]) end) == "15 "
    end

  end
else
  IO.puts RPNForthThing.initialize
end