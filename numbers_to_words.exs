# Numbers to Words

# Original implementation using binary matching:
# The problem with this version is it's 10 times slower than the one below it, based on some simple benchmarking.
# I've left it in for posterity/educational reasons.

# defmodule NumbersToWords do

#   @places ~w[ thousand million billion trillion quadrillion quintillion sextillion septillion octillion nonillion decillion ]

#   # the default entry point, when the argument is an int and not a binary string
#   def parse(int) when is_integer(int) do
#     parse(Integer.to_string(int)) |> String.replace(~r/\s+/, " ") |> String.rstrip
#   end

#   # nought case
#   def parse(""), do: ""

#   # negative integer case
#   def parse(<<?-, the_rest::binary>>), do: "negative " <> parse(the_rest)

#   # ones
#   def parse("0"), do: "zero"
#   def parse("1"), do: "one"
#   def parse("2"), do: "two"
#   def parse("3"), do: "three"
#   def parse("4"), do: "four"
#   def parse("5"), do: "five"
#   def parse("6"), do: "six"
#   def parse("7"), do: "seven"
#   def parse("8"), do: "eight"
#   def parse("9"), do: "nine"

#   # tens
#   def parse("00"), do: ""
#   def parse("10"), do: "ten"
#   def parse("11"), do: "eleven"
#   def parse("12"), do: "twelve"
#   def parse("13"), do: "thirteen"
#   def parse("14"), do: "fourteen"
#   def parse("15"), do: "fifteen"
#   def parse("16"), do: "sixteen"
#   def parse("17"), do: "seventeen"
#   def parse("18"), do: "eighteen"
#   def parse("19"), do: "nineteen"
#   def parse("20"), do: "twenty"

#   # tens, finally with a pattern
#   def parse(<<?2, n::utf8>>), do: "twenty #{parse(<<n>>)}"
#   def parse("30"), do: "thirty"
#   def parse(<<?3, n::utf8>>), do: "thirty #{parse(<<n>>)}"
#   def parse("40"), do: "forty"
#   def parse(<<?4, n::utf8>>), do: "forty #{parse(<<n>>)}"
#   def parse("50"), do: "fifty"
#   def parse(<<?5, n::utf8>>), do: "fifty #{parse(<<n>>)}"
#   def parse("60"), do: "sixty"
#   def parse(<<?6, n::utf8>>), do: "sixty #{parse(<<n>>)}"
#   def parse("70"), do: "seventy"
#   def parse(<<?7, n::utf8>>), do: "seventy #{parse(<<n>>)}"
#   def parse("80"), do: "eighty"
#   def parse(<<?8, n::utf8>>), do: "eighty #{parse(<<n>>)}"
#   def parse("90"), do: "ninety"
#   def parse(<<?9, n::utf8>>), do: "ninety #{parse(<<n>>)}"

#   # tens with a leading zero... drop it
#   def parse(<<?0, n::utf8>>), do: parse(<<n>>)

#   # hundreds with a leading zero... drop it
#   def parse(<<?0, tens::utf8, ones::utf8>>), do: parse(<<tens, ones>>)

#   # regular hundreds
#   def parse(<<hundreds::utf8, tens::utf8, ones::utf8>>), do: "#{parse(<<hundreds>>)} hundred #{parse(<<tens, ones>>)}"

#   #### Thousands and up. now we get fancy ####

#   # General case for splitting up digits 4 or longer, start an "every third digit" state and pass back
#   # Since all binaries fall through to here that also haven't already matched, we have to validate too
#   def parse(<<long_binary::binary>>) when is_binary(long_binary) do
#     if validate?(long_binary) do
#       parse(<<long_binary::binary>>, @places)
#     else
#       raise ArgumentError, message: "Unknown digit(s): #{long_binary}"
#     end
#   end

#   # End case where we run out of words. Oops.
#   def parse(_, []) do
#     raise ArgumentError, message: "Dude. That number is too long. I don't know how to say it."
#   end

#   # End cases (length is 3 or less). no more to parse, drop "every third digit" state, fallback to digit-trio parsing
#   def parse(<<ones::utf8>>, _), do: parse(<<ones::utf8>>)
#   def parse(<<tens::utf8, ones::utf8>>, _), do: parse(<<tens::utf8, ones::utf8>>)
#   def parse(<<hundreds::utf8, tens::utf8, ones::utf8>>, _), do: parse(<<hundreds::utf8, tens::utf8, ones::utf8>>)

#   # thousands and up here... recursive call... this is most of the magic
#   def parse(<<long_binary::binary>>, [illion | rest]) do
#     { further_digits, these_digits } = String.split_at(long_binary, -3)
#     if String.match?(further_digits, ~r/0{3}$/) do
#       # we have to skip the trio join word if the next trio of parseable digits to the left is all zeroes, basically
#       # Otherwise you'd get stuff like "six trillion billion million thousand"
#       parse(<<further_digits::binary>>, rest) <> parse(<<these_digits::binary>>)
#     else
#       parse(<<further_digits::binary>>, rest) <> " #{illion} " <> parse(<<these_digits::binary>>)
#     end
#   end

#   # numeric string validation
#   defp validate?(str) do
#     String.match?(str, ~r/^-?[0-9]+$/)
#   end

# end

# New implementation using divs and mods:

Code.require_file "math_integer_power.exs", __DIR__

defmodule NumbersToWords do
  @moduledoc """
  Converts an integer number like 1234567 to words like
  "one million two hundred thirty four thousand five hundred sixty seven"
  """
  import Math.Integer

  def parse(0), do: "zero"
  def parse(number) when is_integer(number) do
    to_word(number)
    |> List.flatten
    |> Enum.filter(&(&1))
    |> Enum.join(" ")
  end
  def parse(unknown), do: raise(ArgumentError, message: "#{unknown} is not an integer")

  defp to_word(0),  do: [nil]
  defp to_word(1),  do: ["one"]
  defp to_word(2),  do: ["two"]
  defp to_word(3),  do: ["three"]
  defp to_word(4),  do: ["four"]
  defp to_word(5),  do: ["five"]
  defp to_word(6),  do: ["six"]
  defp to_word(7),  do: ["seven"]
  defp to_word(8),  do: ["eight"]
  defp to_word(9),  do: ["nine"]
  defp to_word(10), do: ["ten"]
  defp to_word(11), do: ["eleven"]
  defp to_word(12), do: ["twelve"]
  defp to_word(13), do: ["thirteen"]
  defp to_word(14), do: ["fourteen"]
  defp to_word(15), do: ["fifteen"]
  defp to_word(16), do: ["sixteen"]
  defp to_word(17), do: ["seventeen"]
  defp to_word(18), do: ["eighteen"]
  defp to_word(19), do: ["nineteen"]
  defp to_word(20), do: ["twenty"]
  defp to_word(30), do: ["thirty"]
  defp to_word(40), do: ["forty"]
  defp to_word(50), do: ["fifty"]
  defp to_word(60), do: ["sixty"]
  defp to_word(70), do: ["seventy"]
  defp to_word(80), do: ["eighty"]
  defp to_word(90), do: ["ninety"]
  defp to_word(n) when n < 0, do: ["negative", to_word(-n)]
  defp to_word(n) when n < 100, do: [to_word(div(n,10)*10), to_word(rem(n, 10))]
  defp to_word(n) when n < 1_000, do: [to_word(div(n,100)), "hundred", to_word(rem(n, 100))]
  # dynamically define to_word for thousands and up
  ~w[ thousand million billion trillion quadrillion quintillion sextillion septillion octillion nonillion decillion ]
  |> Enum.zip(2..13)
  |> Enum.each(
    fn {illion, factor} ->
      defp to_word(n) when n < unquote(ipow_10(factor*3)) do
        [to_word(div(n,unquote(ipow_10((factor-1)*3)))), unquote(illion), to_word(rem(n,unquote(ipow_10((factor-1)*3))))]
      end
    end
  )

  defp to_word(_), do: raise(ArgumentError, message: "Dude. That number is too long. I don't know how to say it.")
end



# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule NumbersToWordsTest do
    use ExUnit.Case, async: true

    test "digits to words" do
      ~w[
        zero one two three four five six seven eight nine ten
        eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen
      ]
      |> Enum.zip(0..20)
      |>
      Enum.each(fn {word, num} ->
        assert word == NumbersToWords.parse(num)
      end)
    end

    test "negative" do
      assert "negative one thousand one" == NumbersToWords.parse(-1001)
    end

    test "tens digits to words" do
      assert "twelve" == NumbersToWords.parse(12)
      assert "eighteen" == NumbersToWords.parse(18)
      assert "twenty three" == NumbersToWords.parse(23)
      assert "fifty six" == NumbersToWords.parse(56)
      assert "sixty nine" == NumbersToWords.parse(69)
      assert "ninety five" == NumbersToWords.parse(95)
    end

    test "hundreds numbers to words" do
      assert "one hundred three" == NumbersToWords.parse(103)
      assert "five hundred twelve" == NumbersToWords.parse(512)
      assert "three hundred" == NumbersToWords.parse(300)
    end

    test "thousands numbers to words" do
      assert "four thousand twenty three" == NumbersToWords.parse(4023)
    end

    test "hundred thousand numbers to words" do
      assert "three hundred thousand four" == NumbersToWords.parse(300004)
    end

    test "quadrillion baby" do
      assert "three quadrillion" == NumbersToWords.parse(3000000000000000)
      assert "three quadrillion one" == NumbersToWords.parse(3000000000000001)
    end

    # showoff...
    test "negative quintillion with interspersed digits" do
      assert "negative sixty nine quintillion one billion six hundred ninety million one" == NumbersToWords.parse(-69000000001690000001)
    end

    test "running out of available words raises" do
      assert_raise ArgumentError, "Dude. That number is too long. I don't know how to say it.", fn ->
        NumbersToWords.parse(100000000000000000000000000000000000000000000000000)
      end
    end

    test "unknown characters raise" do
      assert_raise ArgumentError, "r is not an integer", fn -> NumbersToWords.parse("r") end
      assert_raise ArgumentError, "1r5 is not an integer", fn -> NumbersToWords.parse("1r5") end
    end

  end
end

# run this benchmark with "elixir #{__ENV__.file} bm"
# If you have a full-fledged Elixir project, just use Benchfella instead.
if System.argv |> List.first == "bm" do
  defmodule Time do
    def now, do: ({msecs, secs, musecs} = :erlang.now; (msecs*1000000 + secs)*1000000 + musecs)
  end
  defmodule BM do
    def times(0, f), do: f.()
    def times(n, f) do
      f.()
      times(n-1, f)
    end
    def go(f) do
      start = Time.now
      times(1000, f)
      tot = Time.now - start
      ops_per_mus = 1000/tot
      ops_per_s = ops_per_mus * 1000000
      IO.puts "Operations per second: #{ops_per_s}"
      ops_per_s
    end
  end
  BM.go(fn ->
    NumbersToWords.parse(:rand.uniform(999999999999999999999))
  end)
end
