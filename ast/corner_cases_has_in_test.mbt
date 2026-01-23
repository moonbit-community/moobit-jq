///|
/// Corner case tests for has/in membership

///|
test "corner: has() with existing key" {
  debug_inspect(test_query("has(\"a\")", "{\"a\":1}"), content="True")
}

///|
test "corner: has() with missing key" {
  debug_inspect(test_query("has(\"b\")", "{\"a\":1}"), content="False")
}

///|
test "corner: has() with array index" {
  debug_inspect(test_query("has(0)", "[1,2,3]"), content="True")
}

///|
test "corner: has() with out of bounds index" {
  debug_inspect(test_query("has(10)", "[1,2,3]"), content="False")
}

///|
test "corner: in() check key in object" {
  debug_inspect(test_query("in({\"a\":1,\"b\":2})", "\"a\""), content="True")
}

///|
test "corner: in() check missing key" {
  debug_inspect(test_query("in({\"a\":1,\"b\":2})", "\"c\""), content="False")
}
