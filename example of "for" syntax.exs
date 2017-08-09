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
