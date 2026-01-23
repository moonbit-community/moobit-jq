///|
/// Corner case tests for optional access

///|
test "corner: optional object key access" {
  debug_inspect(test_query(".a?", "{\"b\":1}"), content="Null")
}

///|
test "corner: optional array index" {
  debug_inspect(test_query(".[10]?", "[1,2,3]"), content="Null")
}

///|
test "corner: optional nested access" {
  debug_inspect(test_query(".a.b.c?", "{\"a\":{\"b\":{}}}"), content="Null")
}

///|
test "corner: optional with existing value" {
  debug_inspect(test_query(".a?", "{\"a\":42}"), content="Number(42)")
}
