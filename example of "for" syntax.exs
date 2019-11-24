# A list generator:
iex> for n <- [1, 2, 3, 4], do: n * 2
[2, 4, 6, 8]

# A comprehension with two generators
iex> for x <- [1, 2], y <- [2, 3], do: x * y
[2, 3, 4, 6]

# A comprehension with a generator and a filter
iex> for n <- [1, 2, 3, 4, 5, 6], rem(n, 2) == 0, do: n
[2, 4, 6]

# filter using `when`
iex> users = [user: "john", admin: "meg", guest: "barbara"]
iex> for {type, name} when type != :guest <- users do
...>   String.upcase(name)
...> end
["JOHN", "MEG"]

# parse a binary stream/bitstring
iex> pixels = <<213, 45, 132, 64, 76, 32, 76, 0, 0, 234, 32, 15>>
iex> for <<r::8, g::8, b::8 <- pixels>>, do: {r, g, b}
[{213, 45, 132}, {64, 76, 32}, {76, 0, 0}, {234, 32, 15}]

# remove all spaces from a string
iex> for <<c <- " hello world ">>, c != ?\s, into: "", do: <<c>>
"helloworld"

# an upcase echo server
for line <- IO.stream(:stdio, :line), into: IO.stream(:stdio, :line) do
  String.upcase(line)
end

# filtering a bunch of items on a value and extracting another value
room_uuid = "21b2de86-7c75-11e7-8acc-00218628f526"
items = [{1, "Bed", "21b15d72-7c75-11e7-b18d-00218628f526", 1, 490.0, nil},
 {2, "Table", "21b15d72-7c75-11e7-b18d-00218628f526", 1, 105.0, nil},
 {2, "Table", "21b15d72-7c75-11e7-b18d-00218628f526", 1, 105.0, nil},
 {3, "Chair", "21b15d72-7c75-11e7-b18d-00218628f526", 1, 35.0, nil},
 {1, "Bed", "21b1d0c2-7c75-11e7-8c40-00218628f526", 1, 490.0, nil},
 {2, "Table", "21b1d0c2-7c75-11e7-8c40-00218628f526", 1, 105.0, nil},
 {2, "Table", "21b1d0c2-7c75-11e7-8c40-00218628f526", 1, 105.0, nil},
 {3, "Chair", "21b1d0c2-7c75-11e7-8c40-00218628f526", 1, 35.0, nil},
 {1, "Bed", "21b2301c-7c75-11e7-addd-00218628f526", 1, 490.0, nil},
 {2, "Table", "21b2301c-7c75-11e7-addd-00218628f526", 1, 105.0, nil},
 {2, "Table", "21b2301c-7c75-11e7-addd-00218628f526", 1, 105.0, nil},
 {3, "Chair", "21b2301c-7c75-11e7-addd-00218628f526", 1, 35.0, nil},
 {2, "Table", "21b28cba-7c75-11e7-833d-00218628f526", 3, 105.0, nil},
 {3, "Chair", "21b28cba-7c75-11e7-833d-00218628f526", 3, 35.0, nil},
 {8, "Buffet", "21b28cba-7c75-11e7-833d-00218628f526", 3, 210.0, nil},
 {2, "Table", "21b2de86-7c75-11e7-8acc-00218628f526", 4, 105.0, nil},
 {3, "Chair", "21b2de86-7c75-11e7-8acc-00218628f526", 4, 35.0, nil},
 {8, "Buffet", "21b2de86-7c75-11e7-8acc-00218628f526", 4, 210.0, nil}]

# new_items = Enum.filter(items, fn(
#   { _ , _ , ^room_uuid , _room, _ ,_ }) -> true
#   _ -> false
#   end)
new_items = for { _ , _ , ^room_uuid , _room, _ ,_ } = item <- items, do: item
IO.inspect new_items
