defmodule Tail do

  import Kernel, except: [match?: 2]

  def match?("", _) do
    false
  end

  def match?(word, word) do
    true
  end

  def match?(<<_::utf8, rest::binary>>, ending) do
    match?(rest, ending)
  end

  def trunc(text, ending) do
    do_trunc("", text, ending)
  end

  defp do_trunc(stuff, text, text) do
    stuff
  end

  defp do_trunc(stuff, "", _) do
    stuff
  end

  defp do_trunc(accum, <<h::utf8, rest::binary>>, ending) do
    do_trunc(<<accum::binary, h::utf8>>, rest, ending)
  end

  def rstrip(text, strip_char \\ " ") do
    do_rstrip(strip_char, "", "", text)
  end

  defp do_rstrip(sc, whitespace, accum, text) do

end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule TailTest do
    use ExUnit.Case, async: true
    alias Tail, as: T

    test "match end" do
      assert T.match?("Peter was here", "here")
      refute T.match?("Peter was here", "herp")
      refute T.match?("Peter was here", "Peter")
    end

    test "trunc end" do
      assert T.trunc("Peter was here", "here") == "Peter was "
      assert T.trunc("Peter was here", "was") == "Peter was here"
      assert T.trunc("Peter was", "Peter was") == ""
    end

  end
end
