///|
/// Corner case tests for type conversion and checking

///|
test "corner: tojson converts to JSON string" {
  debug_inspect(
    test_query("tojson", "{\"a\":1}"),
    content="String(\"Object({\\\"a\\\": Number(1)})\")",
  )
}

///|
test "corner: fromjson parses JSON string" {
  debug_inspect(
    test_query("fromjson", "\"{\\\"a\\\":1}\""),
    content="Object({\"a\": Number(1)})",
  )
}

///|
test "corner: tojson then fromjson roundtrip" {
  debug_inspect(
    test_query("tojson | fromjson", "{\"a\":1,\"b\":[2,3]}"),
    content=(
      #|EvalError: InvalidOperation("JSON parse error: Invalid character 'O' at line 1, column 0")
    ),
  )
}

///|
test "corner: type of various values" {
  debug_inspect(test_query("type", "null"), content="String(\"null\")")
}

///|
test "corner: type of number" {
  debug_inspect(test_query("type", "42"), content="String(\"number\")")
}

///|
test "corner: type of string" {
  debug_inspect(test_query("type", "\"hello\""), content="String(\"string\")")
}

///|
test "corner: type of array" {
  debug_inspect(test_query("type", "[]"), content="String(\"array\")")
}

///|
test "corner: type of object" {
  debug_inspect(test_query("type", "{}"), content="String(\"object\")")
}

///|
test "corner: type of boolean" {
  debug_inspect(test_query("type", "true"), content="String(\"boolean\")")
}
