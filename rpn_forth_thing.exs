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

defmodule RPNForthThing do

  def initialize do
    initialize(System.argv)
  end
  def initialize(input) when is_binary(input) do
    initialize(String.split(input, " ", trim: true))
  end
  def initialize(input) when is_list(input) do
    input |> normalize |> compute([], HashDict.new)
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

  defp validate_num(num) when is_float(num), do: num
  defp validate_num(num) when is_integer(num), do: num
  defp validate_num(num) when is_binary(num) do
    cond do
      num =~ ~r/^-?[0-9]+$/              -> String.to_integer(num)
      num =~ ~r/^-?[0-9]+(?:\.[0-9]+)?$/ -> String.to_float(num)
      true                           -> :NaN
    end
  end

  def compute([], [last_val], _) do
    last_val
  end

  def compute([], [], _) do
    # just bail
  end

  def compute([ "end" | _ ], stack, _) do
    if Enum.count(stack) == 1 do
      List.first(stack)
    else
      stack
    end
  end

  def compute([ "+" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [x + y | stack], dict)
  end

  def compute([ "-" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [x - y | stack], dict)
  end

  def compute([ "*" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [x * y | stack], dict)
  end

  def compute([ "/" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [x / y | stack], dict)
  end

  def compute([ "**" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [:math.pow(x, y) | stack], dict)
  end

  def compute([ "pi" | remaining_input], stack, dict) do
    compute(remaining_input, [:math.pi | stack], dict)
  end

  def compute([ "sin" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [:math.sin(x) | stack], dict)
  end

  def compute([ "cos" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [:math.cos(x) | stack], dict)
  end

  def compute([ "tan" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [:math.tan(x) | stack], dict)
  end

  def compute([ "sqrt" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [:math.sqrt(x) | stack], dict)
  end

  def compute([ "drop" | remaining_input], [_ | stack], dict) do
    compute(remaining_input, stack, dict)
  end

  def compute([ "dup" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [x, x | stack], dict)
  end

  def compute([ "swap" | remaining_input], [y, x | stack], dict) do
    compute(remaining_input, [x, y | stack], dict)
  end

  # In-place decrement
  def compute([ "1-" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [(x - 1) | stack], dict)
  end

  # In-place increment
  def compute([ "1+" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [(x + 1) | stack], dict)
  end

  # In-place negation
  def compute([ "@-" | remaining_input], [x | stack], dict) do
    compute(remaining_input, [-x | stack], dict)
  end

  # random numbers
  def compute([ "rand" | remaining_input], stack, dict) do
    compute(remaining_input, [Kernel.rand | stack], dict)
  end

  # inspection. just spits out the remaining instructions, and the stack and dict states
  # Sort of, shockingly simple?
  def compute([ "inspect" | remaining_input], stack, dict) do
    IO.puts "Remaining instructions:"
    IO.inspect remaining_input
    IO.puts "Stack:"
    IO.inspect stack
    IO.puts "Dictionary:"
    IO.inspect dict
    compute(remaining_input, stack, dict)
  end

  # Logic/Booleans
  # For the purposes of the following logic, zero is false,
  # anything else is true... although typically a 1 is returned
  # for truths, boolean tests should compare with 0 (falsity) instead of 1

  def compute([ "=" | remaining_input], [y, x | stack], dict) do
    out = if y == x, do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ "<>" | remaining_input], [y, x | stack], dict) do
    out = if y != x, do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ "<" | remaining_input], [y, x | stack], dict) do
    out = if x < y, do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ ">" | remaining_input], [y, x | stack], dict) do
    out = if x > y, do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ "and" | remaining_input], [y, x | stack], dict) do
    out = if ((y != 0) and (x != 0)), do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ "or" | remaining_input], [y, x | stack], dict) do
    out = if ((y != 0) or (x != 0)), do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  def compute([ "not" | remaining_input], [x | stack], dict) do
    out = if x == 0, do: 1, else: 0
    compute(remaining_input, [out | stack], dict)
  end

  # def compute([ "?" | remaining_input], stack, dict) do
  #   compute([ "if" | remaining_input], stack, dict)
  # end

  # If-Else-Then
  # Note that this is a prefix function!
  # Usage: test_val is on top of stack. "if <then-clause> else <else-clause> then"
  # puts then-clause on top of instruction stack if test_val != 0, else-clause if test_val == 0.
  def compute([ "if" | remaining_input], [x | stack], dict) do
    {if_and_possibly_else_clause, ["then" | remaining_input]} = Enum.split_while(remaining_input, fn(ins) -> ins != "then" end)
    if Enum.any?(if_and_possibly_else_clause, fn ins -> ins == "else" end) do
      {if_clause, ["else" | else_clause]} = Enum.split_while(if_and_possibly_else_clause, fn(ins) -> ins != "else" end)
    else
      if_clause = if_and_possibly_else_clause
      else_clause = []
    end
    if x != 0 do
      compute(if_clause ++ remaining_input, stack, dict)
    else
      compute(else_clause ++ remaining_input, stack, dict)
    end
  end

  # Rotation
  # Rotation of an entire list, in elixir, is slow by default.
  # I'm commenting these out for now till I come up with a better implementation.
  # Instead I'll use rot3^ and rot3v to just manipulate the top 3 elements of the stack.

  # This one doesn't work yet because it would be slow as hell
  # def compute([ :"rot^" | remaining_input], stack, dict) do
  #   compute(remaining_input, ???, dict)
  # end

  # This one works but is likely slow
  # def compute([ :"rotv" | remaining_input], [head | stack], dict) do
  #   compute(remaining_input, stack ++ [head], dict)
  # end

  # Rotate the top 3 values on the stack down (assuming top element is bottom-most, like an RPN calculator)
  def compute([ "rot3v" | remaining_input], [x, y, z | stack], dict) do
    compute(remaining_input, [y, z, x | stack], dict)
  end

  # Rotate the top 3 values on the stack up (assuming top element is bottom-most, like an RPN calculator)
  def compute([ "rot3^" | remaining_input], [x, y, z | stack], dict) do
    compute(remaining_input, [z, x, y | stack], dict)
  end

  # Comments
  def compute([ "(" | remaining_input ], stack, dict) do
    {_, [")" | remainder]} = Enum.split_while(remaining_input, fn(ins) -> ins != ")" end)
    compute(remainder, stack, dict)
  end

  # Do loops
  def compute([ "do" | remainder ], [x, y | stack], dict) do
    {the_loop, ["loop" | remainder]} = Enum.split_while(remainder, fn(ins) -> ins != "loop" end)
    # So the forth spec says the do loop goes up to but NOT INCLUDING the last number
    # But in my case the first number can be bigger than the last, so it counts down
    # Call it an enhancement
    # But that means we have to increment or decrement appropriately based on which is bigger.
    end_num = if x < y, do: y-1, else: y+1
    unrolled_loop = Enum.map x..end_num, fn i ->
      # replace each "i" in the loop context with the index value
      Enum.map(the_loop, fn(maybe_i) -> if maybe_i == "i", do: i, else: maybe_i end)
    end
    compute(List.flatten([unrolled_loop | remainder]), stack, dict)
  end

  # new definitions!
  def compute([ ":", name | remaining_input ], stack, dict) do
    {definition, [";" | remainder]} = Enum.split_while(remaining_input, fn(ins) -> ins != ";" end)
    newdict = Dict.put(dict, name, definition)
    compute(remainder, stack, newdict)
  end

  # side effects!
  # Prints the binary of an ascii value on the top of the stack (without carriage return), popping it
  def compute([ "emit" | remaining_input], [x | stack], dict) do
    IO.write <<x>>
    compute(remaining_input, stack, dict)
  end

  # Prints the literal value of the top of the stack, popping it
  def compute([ "." | remaining_input], [x | stack], dict) do
    IO.puts x
    compute(remaining_input, stack, dict)
  end

  # Emits a carriage return
  def compute([ "cr" | remaining_input], stack, dict) do
    IO.puts ""
    compute(remaining_input, stack, dict)
  end

  # Dictionary definition lookup fallthrough
  def compute([ name | remaining_input], stack, dict) when is_binary(name) do
    if Dict.has_key?(dict, name) do
      compute(dict[name] ++ remaining_input, stack, dict)
    else
      raise "Undefined name: #{name}"
    end
  end

  # fallthrough... just passes things through to the stack (like numeric values)
  def compute([n | remaining_input], stack, dict) do
    compute(remaining_input, [n | stack], dict)
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
      assert RPNForthThing.initialize(~w[1.0 2.0 +]) === 3.0
    end

    test "subtracting 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 -]) === 1
    end

    test "multiplying 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 *]) === 6
    end

    test "dividing 2 numbers" do
      assert RPNForthThing.initialize(~w[3 2 /]) === 1.5
    end

    test "sequence of simple math operations" do
      assert RPNForthThing.initialize(~w[ 1 2 3 4 5 * + + + 2 /]) === 13.0
    end

    test "power" do
      assert RPNForthThing.initialize(~w[ 10.0 3.0 ** ]) === 1000.0
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
      assert RPNForthThing.initialize(~w[ 3 5 swap / ]) === 1.6666666666666667
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
      assert RPNForthThing.initialize(~w[ 1 2 3 rot3^ / / ]) == 0.6666666666666666
    end

    test "rotate top 3 elements of stack down" do
      assert RPNForthThing.initialize(~w[ 1 2 3 rot3v / / ]) == 6.0
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
        RPNForthThing.initialize(~w[ 0 10 do i emit loop ])
      end) == <<10, 9, 8, 7, 6, 5, 4, 3, 2, 1>>
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

  end
else
  IO.puts RPNForthThing.initialize
end