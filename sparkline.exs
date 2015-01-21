defmodule Sparkline do

  @zombie %{
    draw: %{
      "1 2.5 3 5, 3 1" => '▁▄▅█▅▁',
      "1 2 3, 5 2 1" => '▁▃▅█▃▁'
    }
  }

  def draw(str) do
    values = str |> String.split(~r/[, ]+/)
                 |> Enum.map(&(elem(Float.parse(&1), 0)))
    {min, max} = {Enum.min(values), Enum.max(values)}
    values |> Enum.map(&(round((&1 - min) / (max - min) * 7 + 0x2581)))
  end

  # should be the last function
  def zombie do
    @zombie
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start
  defmodule SparklineTest do
    use ExUnit.Case, async: true
    test "sparkline" do
      Sparkline.zombie[:draw] |> Enum.each(
        fn {x, y} -> assert Sparkline.draw(x) == y end
      )
    end
  end
end
