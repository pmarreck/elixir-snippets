defmodule RegexEx do

  def match(a,b) when is_binary(a) and is_binary(b) do
    match(a, b, %{stack: [], matches: [], debug: false})
  end

  def match(a,b,:debug) when is_binary(a) and is_binary(b) do
    match(a, b, %{stack: [], matches: [], debug: true})
  end

  def match("",_b,_state = %{stack: _stack, matches: matches, debug: debug}) do
    if debug do
      IO.puts "No regex context left. Returning matches"
    end
    matches
  end

  def match(<<?/, t::binary>>, b, _state = %{stack: [], matches: [], debug: debug}) do
    if debug do
      IO.puts "Beginning regex context"
    end
    match(t, b, %{stack: [:regex_context], matches: [], debug: debug})
  end

  def match(<<?/>>, b, _state = %{stack: [:regex_context], matches: matches, debug: debug}) do
    if debug do
      IO.puts "Ending regex context"
    end
    match("", b, %{stack: [], matches: matches, debug: debug})
  end

  def match(<<_m::utf8, _s::binary>>, <<_n::utf8, _t::binary>>, _state = %{stack: [], matches: _matches, debug: _debug}) do
    raise "no regex state to match on (missing / at start and/or end)"
  end

  # ? modifier, nonspecial character prior

  def match(<<m::utf8, ??, s::binary>>, <<n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) when m == n do
    match(s, t, state)
  end

  def match(<<m::utf8, ??, s::binary>>, rest = <<n::utf8, _t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) when m != n do
    match(s, rest, state)
  end

  # + modifier, nonspecial character prior
  # Rewrite definition based on * (since /ab+c/ == /abb*c/)

  def match(<<m::utf8, ?+, s::binary>>, rest, state = %{stack: _stack, matches: _matches, debug: _debug}) do
    match(<<m::utf8, m::utf8, ?*, s::binary>>, rest, state)
  end

  # def match(r = <<m::utf8, ?+, _s::binary>>, <<n::utf8, o::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) when m == n and m == o do
  #   match(r, <<o::utf8, t::binary>>, state)
  # end

  # def match(<<m::utf8, ?+, s::binary>>, <<n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) when m == n do
  #   match(s, t, state)
  # end

  # * modifier, nonspecial character prior

  def match(r = <<m::utf8, ?*, _s::binary>>, <<n::utf8, o::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: debug}) when m == n and m == o do
    if debug do
      IO.puts "found matching * with >1 match"
      IO.puts "r = #{r}"
      IO.puts "s = #{<<n::utf8, o::utf8, t::binary>>}"
    end
    match(r, <<o::utf8, t::binary>>, state)
  end

  def match(r = <<m::utf8, ?*, _s::binary>>, <<n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: debug}) when m == n do
    if debug do
      IO.puts "found matching * with 1 match"
      IO.puts "r = #{r}"
      IO.puts "s = #{<<n::utf8, t::binary>>}"
    end
    match(r, t, state)
  end

  def match(<<m::utf8, ?*, s::binary>>, "", state = %{stack: _stack, matches: _matches, debug: debug}) do
    if debug do
      IO.puts "found * with empty string, skipping #{<<m::utf8, ?*>>}"
      IO.puts "r = #{<<m::utf8, ?*, s::binary>>}"
    end
    match(s, "", state)
  end

  def match(<<m::utf8, ?*, s::binary>>, rest = <<n::utf8, _t::binary>>, state = %{stack: _stack, matches: _matches, debug: debug}) when m != n do
    if debug do
      IO.puts "found * with no match, skipping #{<<m::utf8, ?*>>}"
      IO.puts "r = #{<<m::utf8, ?*, s::binary>>}"
      IO.puts "rest = #{rest}"
    end
    match(s, rest, state)
  end

  # . (match any character)

  def match(<<?., s::binary>>, _rest = <<_n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) do
    match(s, t, state)
  end

  # match any of a set of characters- start set context
  def match(<<?[, s::binary>>, rest, state = %{stack: stack, matches: matches, debug: debug}) do
    match(s, rest, %{stack: [:set_chars_context | stack], matches: matches, debug: debug})
  end

  # while in chars context, collect set of chars
  # TODO: write code to make this work

  # default match
  def match(<<m::utf8, s::binary>>, <<n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: debug}) when m == n do
    if debug do
      IO.puts "Default match on character #{<<m>>} in both regex and string"
    end
    match(s, t, state)
  end

  # no match at current character, consume string
  def match(r = <<m::utf8, _s::binary>>, <<n::utf8, t::binary>>, state = %{stack: _stack, matches: _matches, debug: _debug}) when m != n do
    match(r, t, state)
  end

  def match(_, _, %{stack: _stack, matches: [], debug: debug}) do
    if debug do
      IO.puts "No match"
    end
    false
  end


end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule RegexExTest do
    use ExUnit.Case, async: true
    alias RegexEx, as: RE

    test "basic exact match" do
      assert RE.match("/abc/","abc")
    end

    test "basic partial match" do
      assert RE.match("/a/", "abc")
    end

    test "match doesn't start at beginning of string" do
      assert RE.match("/fox/", "the quick brown fox")
    end

    test "basic single character match" do
      assert RE.match("/a/","a")
    end

    test "basic nonmatch" do
      refute RE.match("/a/", "b")
    end

    test "? modifier with match present" do
      assert RE.match("/ab?c/", "abc")
    end

    test "? modifier with match not present" do
      assert RE.match("/ab?c/", "ac")
    end

    test "+ modifier with 0 matches" do
      refute RE.match("/ab+c/", "ac")
    end

    test "+ modifier with 1 match" do
      assert RE.match("/ab+c/", "abc")
    end

    test "+ modifier with >1 matches" do
      assert RE.match("/ab+c/", "abbbc")
    end

    test "+ modifier with match to end" do
      assert RE.match("/ab+/", "abbb")
    end

    test "* modifier with 0 matches" do
      assert RE.match("/ab*c/", "ac")
    end

    test "* modifier with 1 match" do
      assert RE.match("/ab*c/", "abc")
    end

    test "* modifier with >1 matches" do
      assert RE.match("/ab*c/", "abbbc")
      assert RE.match("/abb*/", "abbb")
    end

    test ". matching any first character" do
      assert RE.match("/.Rc/", "aRc")
    end

    test ". matching any inner character" do
      assert RE.match("/a.c/", "aRc")
    end

    test ". matching any last character" do
      assert RE.match("/aR./", "aRc")
    end

    test "[] set of characters, no ranges, no modifiers" do
      assert RE.match("/a[bc]d/", "acd")
      assert RE.match("/a[bc]d/", "abd")
    end

    test "missing /" do
      assert_raise RuntimeError, fn -> RE.match("ab", "ab") end
    end


  end
end
