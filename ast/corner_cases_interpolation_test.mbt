///|
/// Corner case tests for string interpolation

///|
test "corner: interpolation with null" {
  debug_inspect(
    test_query("\"Value: \\(.missing)\"", "{}"),
    content="String(\"Value: Null\")",
  )
}

///|
test "corner: interpolation with nested object" {
  debug_inspect(
    test_query("\"User: \\(.user)\"", "{\"user\":{\"name\":\"Alice\"}}"),
    content="String(\"User: Object({\\\"name\\\": String(\\\"Alice\\\")})\")",
  )
}

///|
test "corner: multiple adjacent interpolations" {
  debug_inspect(
    test_query(
      "\"\\(.a)\\(.b)\\(.c)\"", "{\"a\":\"x\",\"b\":\"y\",\"c\":\"z\"}",
    ),
    content="String(\"xyz\")",
  )
}

///|
test "corner: interpolation with calculation" {
  debug_inspect(
    test_query("\"Sum: \\(.a + .b + .c)\"", "{\"a\":1,\"b\":2,\"c\":3}"),
    content=(
      #|String("Sum: Number(6)")
    ),
  )
}
