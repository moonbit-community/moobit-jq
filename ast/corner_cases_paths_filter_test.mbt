///|
/// Corner case tests for paths filters

///|
test "corner: paths with type filter" {
  debug_inspect(
    test_query("paths(type == \"number\")", "{\"a\":{\"b\":1,\"c\":\"x\"}}"),
    content="Array([String(\"a\"), String(\"b\")])",
  )
}

///|
test "corner: paths scalars only" {
  debug_inspect(
    test_query("paths(scalars)", "{\"a\":1,\"b\":{\"c\":2}}"),
    content="",
  )
}
