///|
/// Corner case tests for min/max

///|
test "corner: min_by with empty array returns null" {
  debug_inspect(test_query("min_by(.x)", "[]"), content="Null")
}

///|
test "corner: max_by with empty array returns null" {
  debug_inspect(test_query("max_by(.x)", "[]"), content="Null")
}

///|
test "corner: min_by with single element" {
  debug_inspect(
    test_query("min_by(.x)", "[{\"x\":5}]"),
    content="Object({\"x\": Number(5)})",
  )
}

///|
test "corner: max_by with single element" {
  debug_inspect(
    test_query("max_by(.x)", "[{\"x\":5}]"),
    content="Object({\"x\": Number(5)})",
  )
}
