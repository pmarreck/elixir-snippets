defmodule FizzBuzz do

  def fizzbuzz(n) when is_integer(n), do: fizzbuzz(n, {rem(n,3), rem(n,5)})
  def fizzbuzz(_, {0,0}), do: :fizzbuzz
  def fizzbuzz(_, {0,_}), do: :fizz
  def fizzbuzz(_, {_,0}), do: :buzz
  def fizzbuzz(n, {_,_}), do: n

  # this is more like the ruby style but takes literally like 15x longer (!)
  # def fizzbuzz(n) do
  #   out = "#{if rem(n,3)==0, do: :Fizz}#{if rem(n,5)==0, do: :Buzz}"
  #   if out=="", do: n, else: out
  # end

  def run(i \\ 100), do: (1..i) |> Enum.map(&fizzbuzz/1)

end

FizzBuzz.run 10000000
