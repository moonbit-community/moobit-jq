///|
/// Corner case tests for array slicing

///|
test "corner: negative start index" {
  debug_inspect(
    test_query(".[-2:]", "[1,2,3,4,5]"),
    content="Array([Number(4), Number(5)])",
  )
}

///|
test "corner: negative end index" {
  debug_inspect(
    test_query(".[:-2]", "[1,2,3,4,5]"),
    content="Array([Number(1), Number(2), Number(3)])",
  )
}

///|
test "corner: negative range" {
  debug_inspect(
    test_query(".[-3:-1]", "[1,2,3,4,5]"),
    content="Array([Number(3), Number(4)])",
  )
}

///|
test "corner: slice beyond bounds" {
  debug_inspect(test_query(".[10:20]", "[1,2,3]"), content="Array([])")
}

///|
test "corner: reverse slice" {
  debug_inspect(test_query(".[3:1]", "[1,2,3,4,5]"), content="Array([])")
}
