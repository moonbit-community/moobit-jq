///|
/// Corner case tests for null coalescing and defaults

///|
test "corner: multiple alternatives" {
  debug_inspect(
    test_query(".a // .b // .c // \"default\"", "{\"c\":5}"),
    content="Null",
  )
}

///|
test "corner: alternative with false" {
  debug_inspect(
    test_query(". // \"default\"", "false"),
    content="String(\"default\")",
  )
}

///|
test "corner: alternative with 0" {
  debug_inspect(test_query(". // \"default\"", "0"), content="Number(0)")
}

///|
test "corner: alternative with empty string" {
  debug_inspect(test_query(". // \"default\"", "\"\""), content="String(\"\")")
}
