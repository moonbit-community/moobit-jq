///|
/// Corner case tests for transpose

///|
test "corner: transpose matrix" {
  debug_inspect(
    test_query("transpose", "[[1,2,3],[4,5,6]]"),
    content="Array([Array([Number(1), Number(4)]), Array([Number(2), Number(5)]), Array([Number(3), Number(6)])])",
  )
}

///|
test "corner: transpose with uneven rows" {
  debug_inspect(
    test_query("transpose", "[[1,2,3],[4,5],[6]]"),
    content="Array([Array([Number(1), Number(4), Number(6)]), Array([Number(2), Number(5)]), Array([Number(3)])])",
  )
}

///|
test "corner: transpose empty matrix" {
  debug_inspect(test_query("transpose", "[]"), content="Array([])")
}
