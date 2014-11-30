defmodule Returning do
  defmacro returning(val, do_block) do
    quote do
      val = unquote(val)
      case val, unquote(do_block)
      val
    end
  end
end

ExUnit.start

defmodule ReturningTest do
  use ExUnit.Case, async: true

  import Returning

  test "a returning block returns its parameter" do
    result = returning 1+2 do
      value -> IO.puts "got #{value}"
    end
    assert result == 3
  end

  test "returning block pattern matching" do
    result = returning {:ok, "computer"} do
      { :error, _oops } -> send self, "BOOM"
      { :ok, val } -> send self, val
    end
    assert result == {:ok, "computer"}
    assert_received "computer"
  end
end
