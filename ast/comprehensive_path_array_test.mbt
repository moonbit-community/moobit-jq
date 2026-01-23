///|
/// Comprehensive tests for path and array operations

// ============================================================================
// Path Manipulation Tests
// ============================================================================

///|
test "paths: all paths in nested structure" {
  debug_inspect(
    test_query("paths", "{\"a\":{\"b\":1,\"c\":2}}"),
    content="Array([String(\"a\")]), Array([String(\"a\"), String(\"b\")]), Array([String(\"a\"), String(\"c\")])",
  )
}

///|
test "leaf_paths: only leaf paths" {
  debug_inspect(
    test_query("leaf_paths", "{\"a\":{\"b\":1,\"c\":2},\"d\":3}"),
    content="Array([String(\"a\"), String(\"b\")]), Array([String(\"a\"), String(\"c\")]), Array([String(\"d\")])",
  )
}

///|
test "getpath: retrieve value at path" {
  debug_inspect(
    test_query("getpath([\"a\",\"b\"])", "{\"a\":{\"b\":42,\"c\":10}}"),
    content="Number(42)",
  )
}

///|
test "setpath: set value at path" {
  debug_inspect(
    test_query("setpath([\"a\",\"b\"]; 99)", "{\"a\":{\"b\":1,\"c\":2}}"),
    content="Object({\"a\": Object({\"b\": Number(99), \"c\": Number(2)})})",
  )
}

///|
test "delpaths: delete multiple paths" {
  debug_inspect(
    test_query(
      "delpaths([[\"a\",\"b\"],[\"c\"]])", "{\"a\":{\"b\":1,\"d\":2},\"c\":3,\"e\":4}",
    ),
    content="Object({\"a\": Object({\"d\": Number(2)}), \"e\": Number(4)})",
  )
}

// ============================================================================
// Advanced Array Operations
// ============================================================================

///|
test "nth: get specific element" {
  debug_inspect(test_query("nth(2)", "[10,20,30,40,50]"), content="Number(30)")
}

///|
test "nth: negative index" {
  debug_inspect(test_query("nth(-1)", "[10,20,30,40,50]"), content="Number(50)")
}

///|
test "rindex: find last occurrence" {
  debug_inspect(test_query("rindex(2)", "[1,2,3,2,1]"), content="Number(3)")
}

///|
test "limit: restrict output count" {
  debug_inspect(
    test_query("limit(3; .[])", "[1,2,3,4,5,6,7,8,9,10]"),
    content="Number(1), Number(2), Number(3)",
  )
}

///|
test "walk: transform all values" {
  debug_inspect(
    test_query(
      "walk(if type == \"number\" then . * 2 else . end)", "{\"a\":1,\"b\":{\"c\":2}}",
    ),
    content="Object({\"a\": Number(2), \"b\": Object({\"c\": Number(4)})})",
  )
}
