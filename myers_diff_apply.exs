defmodule MyersDiff do

  def diff(str1, str2) do
    String.myers_difference(str1, str2)
    |> Enum.map(fn {key, val} ->
      case key do
        :eq  -> {:s, String.length(val)}
        :del -> {:d, String.length(val)}
        :ins -> {:i, val}
      end
    end)
  end

  def apply(str, transform) when is_binary(str) and is_list(transform) do
    do_apply("", str, transform)
  end

  defp do_apply(out_str, "", []), do: out_str
  defp do_apply(out_str, in_str, [{:s, 0} | rest]), do: do_apply(out_str, in_str, rest)
  defp do_apply(out_str, in_str, [{:s, skip_num} | rest]) when skip_num > 0 do
    # <<_skip_num :: utf8-size(skip_num), rest>> = in_str
    # Above errors with ** (CompileError) iex:2: size and unit are not supported on utf types :(
    <<char :: utf8, rest_in :: binary>> = in_str
    out_str = <<out_str :: binary, char :: utf8>>
    do_apply(out_str, rest_in, [{:s, (skip_num - 1)} | rest])
  end

  defp do_apply(out_str, in_str, [{:i, insertion} | rest]) when is_binary(insertion) do
    do_apply(out_str <> insertion, in_str, rest)
  end

  defp do_apply(out_str, in_str, [{:d, 0} | rest]), do: do_apply(out_str, in_str, rest)
  defp do_apply(out_str, in_str, [{:d, delete_num} | rest]) when delete_num > 0 do
    <<_char :: utf8, rest_in :: binary>> = in_str
    do_apply(out_str, rest_in, [{:d, (delete_num - 1)} | rest])
  end


end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule MyersDiffTest do
    use ExUnit.Case, async: true

    test "basic compact diff script" do
      assert MyersDiff.diff("this is a test", "this is test") == [s: 8, d: 2, s: 4]
    end

    test "basic skip script" do
      assert MyersDiff.apply("nothing", [s: 7]) == "nothing"
    end

    test "basic skip and insert script" do
      assert MyersDiff.apply("nothing", [s: 7, i: "man"]) == "nothingman"
    end

    test "basic apply script with skip, insert, delete" do
      assert MyersDiff.apply("this is a test", [s: 8, d: 3, i: "T", s: 3, i: "!"]) == "this is Test!"
    end

    test "full circle" do
      str1 = "this is a test"
      str2 = "this is Test!"
      diff_str1_str2 = MyersDiff.diff(str1, str2)
      diff_str2_str1 = MyersDiff.diff(str2, str1)
      assert MyersDiff.apply(str1, diff_str1_str2) == str2
      assert MyersDiff.apply(str2, diff_str2_str1) == str1
    end

    test "large-ish input" do
      str1 = "This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test."
      str2 = "This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. This is a test. IT don't even know. Ths is a test. This is a test. This is a test. This is a teets. This is a test. This is a test. This is a test."
      assert MyersDiff.diff(str1, str2) == [s: 112, i: "I", s: 1, i: " don't even know. T", s: 1, d: 1, s: 57, d: 1, i: "e", s: 1, i: "s", s: 49]
    end

    test "raises when script runs out of input but there are still commands" do
      assert_raise MatchError, fn -> MyersDiff.apply("this is test", [s: 15]) end
      assert_raise MatchError, fn -> MyersDiff.apply("this is test", [s: 8, d: 15]) end
    end

    test "raises when script runs out of commands but there's still input" do
      assert_raise FunctionClauseError, fn -> MyersDiff.apply("this is test", [s: 4]) end
    end
  end
end
