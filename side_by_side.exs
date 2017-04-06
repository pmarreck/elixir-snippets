defmodule SideBySide do

  def test(ary) when is_list(ary) do
    (Enum.dedup(ary) |> length) <= 3
  end

end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule SideBySideTest do
    use ExUnit.Case, async: true

    test "center cluser of 1's" do
      assert SideBySide.test([0,0,0,0,1,1,1,0,0])
    end

    test "multiple clusters" do
      refute SideBySide.test([0,0,1,1,0,0,1,1,0,0])
    end

    test "no clusters" do
      assert SideBySide.test([0,0,0,0,0,0,0])
    end

    test "clusters on each end" do # should this pass? Up to you.
      assert SideBySide.test([1,1,1,0,0,0,1,1,1])
    end

  end
end
