# Transcoded from my Ruby solution here:
# https://github.com/pmarreck/ruby-snippets/blob/master/functional%20fizzbuzz%20without%20conditionals.rb
defmodule FunctionalFizzbuzz do

  # My original solution curried, so I stole the following from:
  # http://blog.patrikstorm.com/function-currying-in-elixir
  def curry(fun) do
    {_, arity} = :erlang.fun_info(fun, :arity)
    curry(fun, arity, [])
  end
  def curry(fun, 0, arguments) do
    apply(fun, Enum.reverse arguments)
  end
  def curry(fun, arity, arguments) do
    fn arg -> curry(fun, arity - 1, [arg | arguments]) end
  end

  def fb(num) do

  end
end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule FunctionalFizzbuzzTest do
    use ExUnit.Case, async: true
    include FunctionalFizzbuzz

    test "output" do
      assert Enum.map((1..5), &fizzbuzz/1) == "1\n2\nFizz\n4\nBuzz\n"
    end

  end
end