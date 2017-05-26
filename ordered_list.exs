defmodule Order do

  def is_ordered?(list) when is_list(list), do: do_is_ordered(true, list)

  defp do_is_ordered(false, _), do: false
  defp do_is_ordered(_, []), do: true
  defp do_is_ordered(accumulated_boolean, [_]), do: accumulated_boolean
  defp do_is_ordered(accumulated_boolean, [x|[y|_xys]=ys]), do: do_is_ordered(accumulated_boolean && (x<=y), ys)

end

# run this inline suite with "elixir #{__ENV__.file} test"
if System.argv |> List.first == "test" do
  ExUnit.start

  defmodule OrderTest do
    use ExUnit.Case, async: true

    test "regular ordered list" do
      assert Order.is_ordered?([1,2,4,5,8,10,12])
    end

    test "unordered list in one location" do
      refute Order.is_ordered?([1,2,4,8,5,10,12])
    end

    test "empty list is ordered" do
      assert Order.is_ordered?([])
    end

    test "list of 1 item is ordered" do
      assert Order.is_ordered?([5])
    end

    test "reverse-order list is not ordered" do
      refute Order.is_ordered?([9,8,6,5,3,2,1])
    end

    test "ordered list except for last item" do
      refute Order.is_ordered?([1,2,3,5,6,7,8,4])
    end

    test "ordered list except for first item" do
      refute Order.is_ordered?([9,1,2,5,6,7,8])
    end
  end
end
