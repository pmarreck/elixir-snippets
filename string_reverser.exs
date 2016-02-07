defmodule StringReverser do

  # beginning case
  def reverse(str) do
    reverse("", str)
  end

  # end case
  def reverse(reversed, "") do
    reversed
  end

  # interim case
  def reverse(reversed, <<first, rest :: binary>>) do
    reverse(<<first, reversed :: binary>>, rest)
  end

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule ReverserTest do
    use ExUnit.Case, async: true
    alias StringReverser, as: SR

    test "reversing empty string" do
      assert "" == SR.reverse("")
    end

    test "reversing name" do
      assert "reteP" == SR.reverse("Peter")
    end
  end
end
