///|
/// Corner case tests for group_by

///|
test "corner: group_by then sum values" {
  debug_inspect(
    test_query(
      "group_by(.type) | map({type: .[0].type, sum: map(.val) | add})", "[{\"type\":\"A\",\"val\":1},{\"type\":\"A\",\"val\":2},{\"type\":\"B\",\"val\":3}]",
    ),
    content=(
      #|ParseError: UnexpectedToken("TPipe", "TRBrace")
    ),
  )
}

///|
test "corner: group_by with empty array" {
  debug_inspect(test_query("group_by(.x)", "[]"), content="Array([])")
}
