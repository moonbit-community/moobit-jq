///|
/// Corner case tests for unique and unique_by

///|
test "corner: unique_by with single attribute" {
  debug_inspect(
    test_query(
      "unique_by(.a)", "[{\"a\":1,\"b\":2},{\"a\":1,\"b\":3},{\"a\":2,\"b\":1}]",
    ),
    content="Array([Object({\"a\": Number(1), \"b\": Number(2)}), Object({\"a\": Number(2), \"b\": Number(1)})])",
  )
}

///|
test "corner: unique_by with empty array" {
  debug_inspect(test_query("unique_by(.x)", "[]"), content="Array([])")
}

///|
test "corner: unique with duplicates" {
  debug_inspect(
    test_query("unique", "[1,2,1,3,2,4]"),
    content="Array([Number(1), Number(2), Number(3), Number(4)])",
  )
}
