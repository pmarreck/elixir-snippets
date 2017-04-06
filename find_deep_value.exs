defmodule EnumTools do

  def find_deep_values(map, value) when is_map(map), do: _find_deep_values(map, value, [], [])

  defp _find_deep_values(map, value, paths, path) when is_map(map) and is_list(paths) and is_list(path) do
    map |> Enum.(
      fn
        val when is_map(val) -> find_deep_values(val, value)
        val when val == value -> true
        _ -> false
      end)
  end
end


# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule FindDeepTest do
    use ExUnit.Case, async: true
    alias EnumTools, as: ET

    test "find a deep value" do
      assert ET.find_deep_values(%{a: %{b: %{c: "d"}, e: "f"}, g: "h"}, "d") == [[:a, :b, :c]]
    end

    # negative case
    test "could not find a deep value" do
      refute ET.find_deep_values(%{a: %{b: %{c: "d"}}}, "f")
    end

  end
end
