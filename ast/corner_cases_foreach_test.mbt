///|
/// Corner case tests for foreach

///|
test "corner: foreach accumulating values" {
  debug_inspect(
    test_query("foreach .[] as $item (0; . + $item)", "[1,2,3]"),
    content="Number(1), Number(3), Number(6)",
  )
}

///|
test "corner: foreach with transformation" {
  debug_inspect(
    test_query("foreach .[] as $item (0; . + $item; . * 2)", "[1,2,3]"),
    content="Number(2), Number(6), Number(12)",
  )
}

///|
test "corner: foreach with empty array" {
  debug_inspect(
    test_query("foreach .[] as $item (0; . + $item)", "[]"),
    content="",
  )
}
