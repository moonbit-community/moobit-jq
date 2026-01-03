///|
/// Corner case tests for entries and map_values

///|
test "corner: map_values on object" {
  inspect(
    test_query("map_values(. * 2)", "{\"a\":1,\"b\":2,\"c\":3}"),
    content="Object({\"a\": Number(2), \"b\": Number(4), \"c\": Number(6)})",
  )
}

///|
test "corner: map_values on empty object" {
  inspect(test_query("map_values(. * 2)", "{}"), content="Object({})")
}

///|
test "corner: to_entries converts object to key-value pairs" {
  inspect(
    test_query("to_entries", "{\"a\":1,\"b\":2}"),
    content="Array([Object({\"key\": String(\"a\"), \"value\": Number(1)}), Object({\"key\": String(\"b\"), \"value\": Number(2)})])",
  )
}

///|
test "corner: from_entries converts back to object" {
  inspect(
    test_query(
      "from_entries", "[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]",
    ),
    content="Object({\"a\": Number(1), \"b\": Number(2)})",
  )
}

///|
test "corner: with_entries transforms object entries" {
  inspect(
    test_query("with_entries(.value *= 2)", "{\"a\":1,\"b\":2}"),
    content="Object({\"a\": Number(2), \"b\": Number(4)})",
  )
}

///|
test "corner: with_entries filters entries" {
  inspect(
    test_query("with_entries(select(.value > 1))", "{\"a\":1,\"b\":2,\"c\":3}"),
    content="Object({\"b\": Number(2), \"c\": Number(3)})",
  )
}
