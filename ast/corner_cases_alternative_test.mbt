///|
/// Corner case tests for null coalescing and defaults

///|
test "corner: multiple alternatives" {
  inspect(
    test_query(".a // .b // .c // \"default\"", "{\"c\":5}"),
    content="Null",
  )
}

///|
test "corner: alternative with false" {
  inspect(
    test_query(". // \"default\"", "false"),
    content="String(\"default\")",
  )
}

///|
test "corner: alternative with 0" {
  inspect(test_query(". // \"default\"", "0"), content="Number(0)")
}

///|
test "corner: alternative with empty string" {
  inspect(test_query(". // \"default\"", "\"\""), content="String(\"\")")
}
