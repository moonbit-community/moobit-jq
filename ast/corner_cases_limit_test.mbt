///|
/// Corner case tests for limit edge cases

///|
test "corner: limit with zero" {
  debug_inspect(test_query("limit(0; 1,2,3)", "null"), content="")
}

///|
test "corner: limit larger than available" {
  debug_inspect(
    test_query("limit(10; 1,2,3)", "null"),
    content="Number(1), Number(2), Number(3)",
  )
}

///|
test "corner: limit with negative number" {
  debug_inspect(test_query("limit(-1; 1,2,3)", "null"), content="")
}
