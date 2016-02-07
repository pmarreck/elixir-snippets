defmodule Utils do
  defmacro repeat(times, do: block) do
    quote do
      for _ <- 1..unquote(times) do
        unquote(block)
      end
    end
  end
end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule RepeatTest do
    use ExUnit.Case, async: true
    import Utils

    test "repeating" do
      repeat(3) do
        send(self, :repeat_ok)
      end
      assert_received :repeat_ok
      assert_received :repeat_ok
      assert_received :repeat_ok
      refute_received :repeat_ok
    end

  end
end
