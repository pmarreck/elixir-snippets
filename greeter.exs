defmodule Greeter do
  def hello(names, country \\ "en")

  def hello(names, country) when is_list(names) do
    names
    |> Enum.join(", ")
    |> hello(country)
  end

  def hello(name, country) when is_binary(name) do
    phrase(country) <> name
  end

  defp phrase("en"), do: "Hello, "
  defp phrase("es"), do: "Hola, "
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule GreeterTest do
    use ExUnit.Case, async: true


    test "greeter without language argument" do
      assert "Hello, Sean, Steve" == Greeter.hello(~w[ Sean Steve ])
    end

    test "greeter with language argument" do
      assert "Hola, Sean, Steve" == Greeter.hello(~w[ Sean Steve ], "es")
    end

  end
end
