///|
/// Corner case tests for error propagation

///|
test "corner: error in pipeline stops execution" {
  inspect(
    test_query(".x | . * 2", "{}"),
    content=(
      #|EvalError: InvalidOperation("Cannot multiply null and number")
    ),
  )
}

///|
test "corner: try catches errors" {
  inspect(test_query("try .x catch \"error\"", "{}"), content="Null")
}

///|
test "corner: try with successful operation" {
  inspect(
    test_query("try .x catch \"error\"", "{\"x\":42}"),
    content="Number(42)",
  )
}
