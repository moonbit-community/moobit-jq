///|
/// Corner case tests for reduce

///|
test "corner: reduce with array elements" {
  debug_inspect(
    test_query("reduce .[] as $item (0; . + $item)", "[1,2,3,4,5]"),
    content="Number(15)",
  )
}

///|
test "corner: reduce with empty array" {
  debug_inspect(
    test_query("reduce .[] as $item (0; . + $item)", "[]"),
    content="Number(0)",
  )
}

///|
test "corner: reduce building object" {
  debug_inspect(
    test_query(
      "reduce .[] as $item ({}; . + {($item.key): $item.value})", "[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]",
    ),
    content="Object({\"a\": Number(1), \"b\": Number(2)})",
  )
}

///|
test "corner: reduce with multiplication" {
  debug_inspect(
    test_query("reduce .[] as $x (1; . * $x)", "[2,3,4]"),
    content="Number(24)",
  )
}
