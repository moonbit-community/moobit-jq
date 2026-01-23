///|
/// Corner case tests for recursive descent

///|
test "corner: recursive descent on nested arrays" {
  debug_inspect(
    test_query("[..]", "[1,[2,[3,[4]]]]"),
    content="Array([Array([Number(1), Array([Number(2), Array([Number(3), Array([Number(4)])])])]), Number(1), Array([Number(2), Array([Number(3), Array([Number(4)])])]), Number(2), Array([Number(3), Array([Number(4)])]), Number(3), Array([Number(4)]), Number(4)])",
  )
}

///|
test "corner: recursive descent on nested objects" {
  debug_inspect(
    test_query("[..]", "{\"a\":{\"b\":{\"c\":1}}}"),
    content="Array([Object({\"a\": Object({\"b\": Object({\"c\": Number(1)})})}), Object({\"b\": Object({\"c\": Number(1)})}), Object({\"c\": Number(1)}), Number(1)])",
  )
}

///|
test "corner: recursive descent with filter" {
  debug_inspect(
    test_query("[.. | numbers]", "{\"a\":1,\"b\":{\"c\":2,\"d\":\"x\"}}"),
    content=(
      #|EvalError: EvalError("Undefined function: numbers")
    ),
  )
}
