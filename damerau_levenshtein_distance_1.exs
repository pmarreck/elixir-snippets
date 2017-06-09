defmodule DamerauLevenshtein do
  
  def distance_1?(example, ideal) do
    regex = generate_dl1_regex(ideal)
    String.match?(example, regex)
  end

  def generate_dl1_regex_str(str) do
    inner_regex_string =
    every_transposition_combination(str) ++
    every_insertion_combination(str) ++
    every_deletion_or_substitution_combination(str)
    |> Enum.join("|")
    "^(?>" <> str <> "|" <> inner_regex_string <> ")$"
  end

  def generate_dl1_regex(str) do
    generate_dl1_regex_str(str)
    |> Regex.compile!
  end

  def every_transposition_combination(word) do
    transpositions(word) |> Enum.reverse
  end

  defp transpositions(word) do
    transpositions([], String.graphemes(word))
    |> Enum.map(&to_word/1)
  end

  defp transpositions(left, [a , b | rest]=_right) do
    transposed = {left, [b, a | rest]}
    [transposed | transpositions([a|left], [b|rest])]
  end

  defp transpositions(_, _), do: []

  defp to_word({left, right}) do
    Enum.join(Enum.reverse(left)) <> Enum.join(right)
  end

  def every_insertion_combination(word) do
    (["." <> word] ++
    insertions(word) ++
    [word <> "."])
    |> Enum.reverse
  end

  defp insertions(word) do
    insertions([], String.graphemes(word))
    |> Enum.map(&to_word/1)
  end

  defp insertions(left, [a , b | rest]=_right) do
    inserted = {left, [a, ".", b | rest]}
    [inserted | insertions([a | left], [b | rest])]
  end
  defp insertions(_, _), do: []

  def every_deletion_or_substitution_combination(word) do
    deletions_substitutions(word)
    |> Enum.reverse
  end

  defp deletions_substitutions(word) do
    deletions_substitutions([], String.graphemes(word))
    |> Enum.map(&to_word/1)
  end

  defp deletions_substitutions(left, [a | rest]=_right) do
    deleted = {left, [".?" | rest]}
    [deleted | deletions_substitutions([a | left], rest)]
  end

  defp deletions_substitutions(_, _), do: []

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule DLD1Test do
    use ExUnit.Case, async: true

    import DamerauLevenshtein

    test "every transposition" do
      assert every_transposition_combination("word") == ~w[ wodr wrod owrd ]
    end

    test "every insertion" do
      assert every_insertion_combination("word") == ~w[ word. wor.d wo.rd w.ord .word ]
    end

    test "every deletion/substitution" do
      assert every_deletion_or_substitution_combination("word") == ~w[ wor.? wo.?d w.?rd .?ord ]
    end

    test "generate_dl1_regex_str" do
      assert generate_dl1_regex_str("word") == "^(?>word|wodr|wrod|owrd|word.|wor.d|wo.rd|w.ord|.word|wor.?|wo.?d|w.?rd|.?ord)$"
    end

    test "single distance_1? deletion" do
      assert distance_1?("wod", "word")
      refute distance_1?("wd", "word")
    end

    test "single distance_1? substitution" do
      assert distance_1?("wofd", "word")
      refute distance_1?("wand", "word")
    end

    test "single distance_1? insertion" do
      assert distance_1?("worfd", "word")
      refute distance_1?("worafd", "word")
    end

    test "single distance_1? transposition" do
      assert distance_1?("wrod", "word")
      refute distance_1?("owdr", "word")
    end

  end
end
