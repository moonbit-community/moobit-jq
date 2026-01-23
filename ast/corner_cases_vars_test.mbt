///|
/// Corner case tests for variable binding

///|
test "corner: multiple variable bindings" {
  debug_inspect(
    test_query(". as $x | 10 as $y | $x + $y", "5"),
    content="Number(15)",
  )
}

///|
test "corner: variable shadowing" {
  debug_inspect(
    test_query(". as $x | (20 as $x | $x)", "10"),
    content="Number(20)",
  )
}

///|
test "corner: variable in nested context" {
  debug_inspect(
    test_query(". as $x | [1,2,3] | map(. + $x)", "10"),
    content="Array([Number(11), Number(12), Number(13)])",
  )
}
