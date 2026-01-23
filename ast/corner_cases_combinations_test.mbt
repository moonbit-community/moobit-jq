///|
/// Corner case tests for combinations

///|
test "corner: combinations of two arrays" {
  debug_inspect(
    test_query("[[1,2],[3,4]] | combinations", "null"),
    content="Array([Number(1), Number(3)]), Array([Number(1), Number(4)]), Array([Number(2), Number(3)]), Array([Number(2), Number(4)])",
  )
}

///|
test "corner: combinations with empty array" {
  debug_inspect(test_query("[[], [1,2]] | combinations", "null"), content="")
}

///|
test "corner: combinations of three arrays" {
  debug_inspect(
    test_query("[[1,2],[3],[4,5]] | combinations", "null"),
    content="Array([Number(1), Number(3), Number(4)]), Array([Number(1), Number(3), Number(5)]), Array([Number(2), Number(3), Number(4)]), Array([Number(2), Number(3), Number(5)])",
  )
}
