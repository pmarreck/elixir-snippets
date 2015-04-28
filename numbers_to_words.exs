# numbers to words

defmodule NumbersToWords do

  @places ~w[ thousand million billion trillion quadrillion quintillion sextillion septillion octillion nonillion decillion ]


  # the default entry point, when the argument is an int and not a binary string
  def parse(int) when is_integer(int) do
    parse(Integer.to_string(int)) |> String.replace("  ", " ") |> String.rstrip
  end

  # nought case
  def parse(""), do: ""

  # negative case
  def parse(<<?-, the_rest::binary>>), do: "negative " <> parse(the_rest)

  # ones
  def parse("0"), do: "zero"
  def parse("1"), do: "one"
  def parse("2"), do: "two"
  def parse("3"), do: "three"
  def parse("4"), do: "four"
  def parse("5"), do: "five"
  def parse("6"), do: "six"
  def parse("7"), do: "seven"
  def parse("8"), do: "eight"
  def parse("9"), do: "nine"

  # fallthrough case for any binary strings that haven't matched yet
  def parse(<<unknown::utf8>>) when is_binary(unknown) do
    IO.puts "parsing #{unknown}"
    raise ArgumentError, message: "Unknown digit(s): #{unknown}"
  end

  # tens
  def parse("00"), do: ""
  def parse("10"), do: "ten"
  def parse("11"), do: "eleven"
  def parse("12"), do: "twelve"
  def parse("13"), do: "thirteen"
  def parse("14"), do: "fourteen"
  def parse("15"), do: "fifteen"
  def parse("16"), do: "sixteen"
  def parse("17"), do: "seventeen"
  def parse("18"), do: "eighteen"
  def parse("19"), do: "nineteen"
  def parse("20"), do: "twenty"
  def parse(<<?2, n::utf8>>), do: "twenty #{parse(<<n>>)}"
  def parse("30"), do: "thirty"
  def parse(<<?3, n::utf8>>), do: "thirty #{parse(<<n>>)}"
  def parse("40"), do: "forty"
  def parse(<<?4, n::utf8>>), do: "forty #{parse(<<n>>)}"
  def parse("50"), do: "fifty"
  def parse(<<?5, n::utf8>>), do: "fifty #{parse(<<n>>)}"
  def parse("60"), do: "sixty"
  def parse(<<?6, n::utf8>>), do: "sixty #{parse(<<n>>)}"
  def parse("70"), do: "seventy"
  def parse(<<?7, n::utf8>>), do: "seventy #{parse(<<n>>)}"
  def parse("80"), do: "eighty"
  def parse(<<?8, n::utf8>>), do: "eighty #{parse(<<n>>)}"
  def parse("90"), do: "ninety"
  def parse(<<?9, n::utf8>>), do: "ninety #{parse(<<n>>)}"

  # tens with a leading zero... drop it
  def parse(<<?0, n::utf8>>), do: parse(<<n>>)

  # hundreds with a leading zero
  def parse(<<?0, tens::utf8, ones::utf8>>), do: parse(<<tens, ones>>)

  # regular hundreds
  def parse(<<hundreds::utf8, tens::utf8, ones::utf8>>), do: "#{parse(<<hundreds>>)} hundred #{parse(<<tens, ones>>)}"

  #### thousands and up. now we get fancy ####

  # General case for splitting up digits 4 or longer, start an "every third digit" state and pass back
  # Since all binaries fall through to here that also haven't already matched, we have to validate too
  def parse(<<long_binary::binary>>) when is_binary(long_binary) do
    if validate?(long_binary) do
      parse(<<long_binary::binary>>, @places)
    else
      raise ArgumentError, message: "Unknown digit(s): #{long_binary}"
    end
  end

  defp validate?(str) do
    String.match?(str, ~r/^-?[0-9]+$/)
  end

  # end cases (length is 3 or less). no more to parse, drop "every third digit" state, fallback to digit-trio parsing
  def parse(<<ones::utf8>>, _), do: parse(<<ones::utf8>>)
  def parse(<<tens::utf8, ones::utf8>>, _), do: parse(<<tens::utf8, ones::utf8>>)
  def parse(<<hundreds::utf8, tens::utf8, ones::utf8>>, _), do: parse(<<hundreds::utf8, tens::utf8, ones::utf8>>)

  # thousands and up here... recursive call... this is most of the magic
  def parse(<<long_binary::binary>>, [next | rest]) do
    { further_digits, these_digits } = String.split_at(long_binary, -3)
    if String.match?(further_digits, ~r/0{3}$/) do
      # we have to skip the trio join word if the next trio of parseable digits to the left is all zeroes basically
      parse(<<further_digits::binary>>, rest) <> parse(<<these_digits::binary>>)
    else
      parse(<<further_digits::binary>>, rest) <> " #{next} " <> parse(<<these_digits::binary>>)
    end
  end

end



# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule NumbersToWordsTest do
    use ExUnit.Case, async: true

    test "single digits to words" do
      %{zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9}
      |>
      Enum.each(fn {word, num} ->
        assert to_string(word) == NumbersToWords.parse(num)
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

    test "three zeroes" do
      assert "" == NumbersToWords.parse("000")
    end

    test "quadrillion baby" do
      assert "three quadrillion" == NumbersToWords.parse(3000000000000000)
      assert "three quadrillion one" == NumbersToWords.parse(3000000000000001)
    end

    # showoff...
    test "negative quintillion with interspersed digits" do
      assert "negative sixty nine quintillion one billion six hundred ninety million one" == NumbersToWords.parse(-69000000001690000001)
    end

    test "unknown characters raise" do
      assert_raise ArgumentError, "Unknown digit(s): r", fn -> NumbersToWords.parse("r") end
      assert_raise ArgumentError, "Unknown digit(s): r5", fn -> NumbersToWords.parse("1r5") end
    end

  end
end
