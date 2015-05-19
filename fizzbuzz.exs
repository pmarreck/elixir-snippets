defmodule FizzBuzz do

  def fizzbuzz(n) when is_integer(n), do: fizzbuzz(n, rem(n,15))
  def fizzbuzz(_, 3),  do: :fizz
  def fizzbuzz(_, 6),  do: :fizz
  def fizzbuzz(_, 9),  do: :fizz
  def fizzbuzz(_, 12), do: :fizz
  def fizzbuzz(_, 5),  do: :buzz
  def fizzbuzz(_, 10), do: :buzz
  def fizzbuzz(_, 0),  do: :fizzbuzz
  def fizzbuzz(n, _),  do: n

  # this is more like the ruby style but takes literally like 15x longer (!)
  # def fizzbuzz(n) do
  #   out = "#{if rem(n,3)==0, do: :Fizz}#{if rem(n,5)==0, do: :Buzz}"
  #   if out=="", do: n, else: out
  # end

  def run(i \\ 100), do: (1..i) |> Enum.map(&fizzbuzz/1)

  def test do
    unless run(15) == [1, 2, :fizz, 4, :buzz, :fizz, 7, 8, :fizz, :buzz, 11, :fizz, 13, 14, :fizzbuzz], do: raise "something is wrong in #{__MODULE__}"
  end

end

FizzBuzz.test
FizzBuzz.run 10000000
